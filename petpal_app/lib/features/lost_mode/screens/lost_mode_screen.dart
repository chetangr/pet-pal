import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/lost_mode/models/lost_pet.dart';
import 'package:petpal/features/lost_mode/providers/lost_mode_provider.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/features/pets/widgets/pet_avatar.dart';
import 'package:petpal/widgets/loading_indicator.dart';
import 'package:petpal/widgets/error_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class LostModeScreen extends ConsumerStatefulWidget {
  final String petId;
  
  const LostModeScreen({
    Key? key,
    required this.petId,
  }) : super(key: key);

  @override
  ConsumerState<LostModeScreen> createState() => _LostModeScreenState();
}

class _LostModeScreenState extends ConsumerState<LostModeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _isActivating = false;
  bool _isLoading = false;
  bool _hasLocationPermission = false;
  LatLng? _currentLocation;
  double _alertRadius = 5.0; // Default 5km
  final _contactController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isPublic = true;
  
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _contactController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
  
  Future<void> _checkLocationPermission() async {
    final permission = await Permission.location.status;
    
    setState(() {
      _hasLocationPermission = permission.isGranted;
    });
    
    if (!permission.isGranted) {
      // Request permission
      final result = await Permission.location.request();
      
      setState(() {
        _hasLocationPermission = result.isGranted;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    if (!_hasLocationPermission) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      // Move map camera to current location
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation!,
              zoom: 14.0,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _activateLostMode() async {
    if (_currentLocation == null) {
      _showErrorSnackBar('Location is required to activate lost mode');
      return;
    }
    
    if (_contactController.text.isEmpty) {
      _showErrorSnackBar('Contact information is required');
      return;
    }
    
    setState(() {
      _isActivating = true;
    });
    
    try {
      final lostPet = LostPet(
        id: '',
        petId: widget.petId,
        status: LostPetStatus.searching,
        reportedAt: DateTime.now(),
        lastLatitude: _currentLocation!.latitude,
        lastLongitude: _currentLocation!.longitude,
        lastLocationUpdate: DateTime.now(),
        details: _detailsController.text.isNotEmpty ? _detailsController.text : null,
        contactInfo: _contactController.text,
        reportedBy: '',
        alertRadius: _alertRadius,
        isPublic: _isPublic,
        notifiedUsers: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Report as lost
      final lostPetId = await ref.read(lostPetsProvider.notifier).reportLostPet(lostPet);
      
      if (lostPetId == null) {
        _showErrorSnackBar('Failed to report pet as lost');
        setState(() {
          _isActivating = false;
        });
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lost mode activated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh lost pet data
      ref.refresh(lostPetByIdProvider(widget.petId));
      
      // Pop back to pet detail
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error activating lost mode: $e');
      _showErrorSnackBar('Error activating lost mode: $e');
    } finally {
      setState(() {
        _isActivating = false;
      });
    }
  }
  
  Future<void> _deactivateLostMode(LostPet lostPet) async {
    if (_isActivating) return;
    
    setState(() {
      _isActivating = true;
    });
    
    try {
      // Mark as found
      final success = await ref.read(lostPetsProvider.notifier).markAsFound(lostPet.id);
      
      if (!success) {
        _showErrorSnackBar('Failed to deactivate lost mode');
        setState(() {
          _isActivating = false;
        });
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet marked as found!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh lost pet data
      ref.refresh(lostPetByIdProvider(widget.petId));
      
      // Pop back to pet detail
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error deactivating lost mode: $e');
      _showErrorSnackBar('Error deactivating lost mode: $e');
    } finally {
      setState(() {
        _isActivating = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _shareLostPet(LostPet lostPet, String petName) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final locationInfo = lostPet.hasLocation
        ? 'Last seen near (${lostPet.lastLatitude!.toStringAsFixed(6)}, ${lostPet.lastLongitude!.toStringAsFixed(6)})'
        : 'Location unknown';
    
    final shareText = '''
LOST PET: $petName

Last seen on ${dateFormat.format(lostPet.reportedAt)}
$locationInfo

${lostPet.details ?? ''}

If found, please contact:
${lostPet.contactInfo}

This alert was created using PetPal app.
''';
    
    Share.share(shareText, subject: 'LOST PET: $petName');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final petAsync = ref.watch(petProvider(widget.petId));
    final lostPetAsync = ref.watch(lostPetByIdProvider(widget.petId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost Mode'),
        backgroundColor: lostPetAsync.valueOrNull != null && lostPetAsync.value!.status == LostPetStatus.searching
            ? Colors.red
            : null,
      ),
      body: petAsync.when(
        data: (pet) {
          if (pet == null) {
            return const ErrorView(
              title: 'Pet Not Found',
              message: 'The pet you are looking for does not exist.',
              actionLabel: 'Go Home',
              routeAction: '/home',
            );
          }
          
          return lostPetAsync.when(
            data: (lostPet) {
              if (lostPet != null && lostPet.status == LostPetStatus.searching) {
                // Pet is currently in lost mode
                return _buildActiveLostMode(context, pet, lostPet);
              }
              
              // Pet is not lost - show activation screen
              return _buildActivationScreen(context, pet);
            },
            loading: () => const LoadingIndicator(),
            error: (error, stackTrace) => ErrorView(
              title: 'Error',
              message: 'Failed to check lost mode status: $error',
              actionLabel: 'Retry',
              onAction: () {
                ref.refresh(lostPetByIdProvider(widget.petId));
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorView(
          title: 'Error',
          message: 'Failed to load pet: $error',
          actionLabel: 'Go Home',
          routeAction: '/home',
        ),
      ),
    );
  }
  
  Widget _buildActivationScreen(BuildContext context, PetModel pet) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    
    // Pre-fill contact info if available
    if (_contactController.text.isEmpty && user != null) {
      if (user.phone != null) {
        _contactController.text = 'Phone: ${user.phone}';
      } else {
        _contactController.text = 'Email: ${user.email}';
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet info header
          Center(
            child: Column(
              children: [
                PetAvatar(pet: pet, size: 80),
                const SizedBox(height: 16),
                Text(
                  pet.name,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.type.name} • ${pet.breed}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Warning message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow.shade700),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.yellow.shade800,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Activating lost mode will alert nearby PetPal users about your lost pet.',
                    style: TextStyle(
                      color: Colors.yellow.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Location map
          Text(
            'Last Known Location',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (!_hasLocationPermission)
            ElevatedButton.icon(
              onPressed: _checkLocationPermission,
              icon: const Icon(Icons.location_on),
              label: const Text('Grant Location Permission'),
            )
          else if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_currentLocation == null)
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Get Current Location'),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('current'),
                    position: _currentLocation!,
                    infoWindow: InfoWindow(
                      title: pet.name,
                      snippet: 'Last known location',
                    ),
                  ),
                },
                circles: {
                  Circle(
                    circleId: const CircleId('alert_radius'),
                    center: _currentLocation!,
                    radius: _alertRadius * 1000, // Convert km to meters
                    fillColor: Colors.red.withOpacity(0.1),
                    strokeColor: Colors.red,
                    strokeWidth: 1,
                  ),
                },
                onMapCreated: (controller) {
                  _mapController.complete(controller);
                },
                myLocationEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Alert radius slider
          Text(
            'Alert Radius: ${_alertRadius.toStringAsFixed(1)} km',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _alertRadius,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            label: '${_alertRadius.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() {
                _alertRadius = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Contact information
          Text(
            'Contact Information',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Phone or email',
              hintText: 'How can people reach you?',
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 16),
          
          // Additional details
          Text(
            'Additional Details',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            decoration: const InputDecoration(
              labelText: 'Details about your pet',
              hintText: 'Distinctive features, collar color, etc.',
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // Public/private toggle
          SwitchListTile(
            title: const Text('Make Alert Public'),
            subtitle: const Text('Allow all PetPal users to see this alert'),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Activate button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isActivating ? null : _activateLostMode,
              icon: const Icon(Icons.warning_amber_rounded),
              label: _isActivating
                  ? const CircularProgressIndicator()
                  : const Text('Activate Lost Mode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveLostMode(BuildContext context, PetModel pet, LostPet lostPet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    final lostDuration = lostPet.getLostDuration();
    final durationText = lostDuration.inDays > 0
        ? '${lostDuration.inDays} days'
        : lostDuration.inHours > 0
            ? '${lostDuration.inHours} hours'
            : '${lostDuration.inMinutes} minutes';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  '${pet.name} IS LOST',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lost for $durationText',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Pet info
          Center(
            child: Column(
              children: [
                PetAvatar(pet: pet, size: 80),
                const SizedBox(height: 16),
                Text(
                  pet.name,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.type.name} • ${pet.breed}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lost info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lost Information',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Date',
                    dateFormat.format(lostPet.reportedAt),
                    Icons.calendar_today,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Time',
                    timeFormat.format(lostPet.reportedAt),
                    Icons.access_time,
                  ),
                  if (lostPet.details != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      'Details',
                      lostPet.details!,
                      Icons.info_outline,
                      multiLine: true,
                    ),
                  ],
                  const Divider(),
                  _buildInfoRow(
                    'Contact',
                    lostPet.contactInfo,
                    Icons.contact_phone,
                    multiLine: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Location map
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Known Location',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (lostPet.hasLocation)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            lostPet.lastLatitude!,
                            lostPet.lastLongitude!,
                          ),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('last_location'),
                            position: LatLng(
                              lostPet.lastLatitude!,
                              lostPet.lastLongitude!,
                            ),
                            infoWindow: InfoWindow(
                              title: pet.name,
                              snippet: 'Last known location',
                            ),
                          ),
                        },
                        circles: {
                          Circle(
                            circleId: const CircleId('alert_radius'),
                            center: LatLng(
                              lostPet.lastLatitude!,
                              lostPet.lastLongitude!,
                            ),
                            radius: lostPet.alertRadius * 1000, // Convert km to meters
                            fillColor: Colors.red.withOpacity(0.1),
                            strokeColor: Colors.red,
                            strokeWidth: 1,
                          ),
                        },
                        myLocationEnabled: true,
                        compassEnabled: true,
                        mapToolbarEnabled: false,
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No location information available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (lostPet.hasLocation && lostPet.lastLocationUpdate != null)
                    Text(
                      'Updated: ${DateFormat('MMM d, h:mm a').format(lostPet.lastLocationUpdate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareLostPet(lostPet, pet.name),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isActivating 
                      ? null 
                      : () => _deactivateLostMode(lostPet),
                  icon: const Icon(Icons.check_circle_outline),
                  label: _isActivating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Found'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Update location button
          if (lostPet.hasLocation)
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (!_hasLocationPermission) {
                    await _checkLocationPermission();
                    if (!_hasLocationPermission) return;
                  }
                  
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    final locationService = ref.read(locationServiceProvider);
                    final position = await locationService.getCurrentPosition();
                    
                    // Update location
                    await ref.read(lostPetsProvider.notifier).updateLocation(
                      lostPet.id,
                      position.latitude,
                      position.longitude,
                    );
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    // Refresh lost pet data
                    ref.refresh(lostPetByIdProvider(widget.petId));
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating location: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Update Location'),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, {bool multiLine = false}) {
    return Row(
      crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}