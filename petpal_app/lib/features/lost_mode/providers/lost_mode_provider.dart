import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/lost_mode/models/lost_pet.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:uuid/uuid.dart';

/// Provider for lost pets list
final lostPetsProvider = StateNotifierProvider<LostPetNotifier, AsyncValue<List<LostPet>>>(
  (ref) {
    final supabaseService = ref.watch(supabaseServiceProvider);
    final localStorageService = ref.watch(localStorageServiceProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    
    return LostPetNotifier(
      supabaseService: supabaseService,
      localStorageService: localStorageService,
      userId: userId,
    );
  },
);

/// Provider for lost pet by ID
final lostPetByIdProvider = FutureProvider.family<LostPet?, String>((ref, petId) async {
  final lostPetsAsync = ref.watch(lostPetsProvider);
  
  return lostPetsAsync.when(
    data: (lostPets) {
      // Find active lost pet record for this pet
      return lostPets.firstWhere(
        (lostPet) => lostPet.petId == petId && lostPet.status == LostPetStatus.searching,
        orElse: () => null!,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for lost mode status of a pet
final lostModeStatusProvider = Provider.family<LostModeStatus, String>((ref, petId) {
  final lostPetAsync = ref.watch(lostPetByIdProvider(petId));
  
  return lostPetAsync.when(
    data: (lostPet) {
      if (lostPet == null) {
        return LostModeStatus.normal;
      }
      
      return lostPet.status == LostPetStatus.searching
          ? LostModeStatus.lost
          : LostModeStatus.found;
    },
    loading: () => LostModeStatus.loading,
    error: (_, __) => LostModeStatus.error,
  );
});

/// Provider for nearby lost pets
final nearbyLostPetsProvider = FutureProvider<List<LostPet>>((ref) async {
  final lostPetsAsync = ref.watch(lostPetsProvider);
  final locationService = ref.watch(locationServiceProvider);
  
  return lostPetsAsync.when(
    data: (lostPets) async {
      // Get current location
      try {
        final position = await locationService.getCurrentPosition();
        
        // Filter for active lost pets that are nearby (within 10km by default)
        const defaultRadius = 10.0; // km
        
        final nearbyPets = lostPets.where((lostPet) {
          if (lostPet.status != LostPetStatus.searching) {
            return false;
          }
          
          if (!lostPet.hasLocation) {
            return false;
          }
          
          // Calculate distance between current position and pet's last known location
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            lostPet.lastLatitude!,
            lostPet.lastLongitude!,
          );
          
          // Convert to kilometers and check against alert radius
          final distanceKm = distance / 1000;
          return distanceKm <= (lostPet.alertRadius.isNaN ? defaultRadius : lostPet.alertRadius);
        }).toList();
        
        return nearbyPets;
      } catch (e) {
        debugPrint('Error getting location: $e');
        return [];
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for location service
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Notifier for managing lost pets
class LostPetNotifier extends StateNotifier<AsyncValue<List<LostPet>>> {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final String? _userId;
  final _uuid = const Uuid();
  
  LostPetNotifier({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
    String? userId,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService,
        _userId = userId,
        super(const AsyncValue.loading()) {
    // Initialize state
    if (_userId != null) {
      loadLostPets();
    } else {
      state = const AsyncValue.data([]);
    }
  }
  
  /// Load lost pets
  Future<void> loadLostPets({bool forceRefresh = false}) async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    try {
      state = const AsyncValue.loading();
      
      // Initialize local storage
      await _localStorageService.init();
      
      // TODO: Implement local storage for lost pets
      
      // Fetch from Supabase
      try {
        // First get pets reported by the user
        final reportedPets = await _supabaseService.fetch(
          'lost_pets',
          column: 'reported_by',
          value: _userId,
        );
        
        // Then get public lost pets or pets where the user is notified
        // This would need a more complex query in a real implementation
        final publicPets = await _supabaseService.fetch(
          'lost_pets',
          column: 'is_public',
          value: true,
        );
        
        // Combine and de-duplicate
        final combinedPets = {
          ...reportedPets.map((json) => LostPet.fromJson(json)),
          ...publicPets.map((json) => LostPet.fromJson(json)),
        }.toList();
        
        // Update state with remote data
        state = AsyncValue.data(combinedPets);
      } catch (e) {
        // Show error
        state = AsyncValue.error(e, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Report a pet as lost
  Future<String?> reportLostPet(LostPet lostPet) async {
    if (_userId == null) return null;
    
    try {
      // Generate ID if not provided
      final id = lostPet.id.isEmpty ? _uuid.v4() : lostPet.id;
      
      // Create new lost pet record with current timestamp
      final newLostPet = lostPet.copyWith(
        id: id,
        reportedBy: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to Supabase
      await _supabaseService.create(
        'lost_pets',
        newLostPet.toJson(),
      );
      
      // Update state
      state = await state.whenData((lostPets) => [...lostPets, newLostPet]);
      
      return id;
    } catch (e) {
      debugPrint('Error reporting lost pet: $e');
      return null;
    }
  }
  
  /// Mark a pet as found
  Future<bool> markAsFound(String lostPetId) async {
    try {
      final lostPetAsync = state;
      if (lostPetAsync is AsyncData<List<LostPet>>) {
        final lostPets = lostPetAsync.value;
        final lostPet = lostPets.firstWhere(
          (pet) => pet.id == lostPetId,
          orElse: () => null!,
        );
        
        if (lostPet != null) {
          final updatedLostPet = lostPet.markAsFound();
          
          // Update in Supabase
          await _supabaseService.update(
            'lost_pets',
            lostPetId,
            updatedLostPet.toJson(),
          );
          
          // Update state
          state = AsyncValue.data(lostPets.map((pet) {
            if (pet.id == lostPetId) {
              return updatedLostPet;
            }
            return pet;
          }).toList());
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error marking pet as found: $e');
      return false;
    }
  }
  
  /// Update the location of a lost pet
  Future<bool> updateLocation(String lostPetId, double latitude, double longitude) async {
    try {
      final lostPetAsync = state;
      if (lostPetAsync is AsyncData<List<LostPet>>) {
        final lostPets = lostPetAsync.value;
        final lostPet = lostPets.firstWhere(
          (pet) => pet.id == lostPetId,
          orElse: () => null!,
        );
        
        if (lostPet != null) {
          final updatedLostPet = lostPet.updateLocation(latitude, longitude);
          
          // Update in Supabase
          await _supabaseService.update(
            'lost_pets',
            lostPetId,
            updatedLostPet.toJson(),
          );
          
          // Update state
          state = AsyncValue.data(lostPets.map((pet) {
            if (pet.id == lostPetId) {
              return updatedLostPet;
            }
            return pet;
          }).toList());
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating lost pet location: $e');
      return false;
    }
  }
  
  /// Get active lost pet for a specific pet
  Future<LostPet?> getActiveLostPet(String petId) async {
    final lostPetAsync = state;
    if (lostPetAsync is AsyncData<List<LostPet>>) {
      final lostPets = lostPetAsync.value;
      
      // Find active lost pet record
      return lostPets.firstWhere(
        (lostPet) => lostPet.petId == petId && lostPet.status == LostPetStatus.searching,
        orElse: () => null!,
      );
    }
    
    return null;
  }
}

/// Service for handling device location
class LocationService {
  /// Get current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return Future.error('Location permissions are permanently denied.');
    } 

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }
  
  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}

/// Status of a pet's lost mode
enum LostModeStatus {
  normal,
  lost,
  found,
  loading,
  error,
}