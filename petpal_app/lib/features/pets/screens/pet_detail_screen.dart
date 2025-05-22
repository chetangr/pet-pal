import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/pets/models/pet.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/features/pets/widgets/pet_avatar.dart';
import 'package:petpal/features/pets/widgets/info_item.dart';
import 'package:petpal/features/pets/widgets/photo_gallery.dart';
import 'package:petpal/features/reminders/providers/reminder_provider.dart';
import 'package:petpal/features/reminders/widgets/reminder_card.dart';
import 'package:petpal/features/journal/widgets/recent_journal_card.dart';
import 'package:petpal/features/home/widgets/home_section.dart';
import 'package:petpal/widgets/loading_indicator.dart';
import 'package:petpal/widgets/error_view.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final String petId;
  
  const PetDetailScreen({
    Key? key,
    required this.petId,
  }) : super(key: key);

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load pet reminders
    Future.microtask(() {
      ref.read(remindersProvider.notifier).loadReminders(petId: widget.petId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final petAsync = ref.watch(petProvider(widget.petId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Profile'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.edit),
            onPressed: () {
              context.push('/home/pet/${widget.petId}/edit');
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'health',
                child: Text('Health Records'),
              ),
              const PopupMenuItem(
                value: 'medication',
                child: Text('Medications'),
              ),
              const PopupMenuItem(
                value: 'weight',
                child: Text('Weight History'),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Share Profile'),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: Text('Generate QR Code'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Data'),
              ),
              const PopupMenuItem(
                value: 'lost',
                child: Text('Report Lost'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Pet'),
              ),
            ],
          ),
        ],
      ),
      body: petAsync.when(
        data: (pet) {
          if (pet == null) {
            return const ErrorView(
              title: 'Pet Not Found',
              message: 'The pet you are looking for does not exist.',
            );
          }
          
          return _buildPetDetail(context, pet);
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorView(
          title: 'Error',
          message: 'Failed to load pet: $error',
        ),
      ),
    );
  }
  
  Widget _buildPetDetail(BuildContext context, PetModel pet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reminders = ref.watch(petRemindersProvider(pet.id));
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(petProvider(widget.petId));
        ref.read(remindersProvider.notifier).loadReminders(
          petId: widget.petId,
          forceRefresh: true,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pet photo and basic info
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PetAvatar(
                        pet: pet,
                        size: 80,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: theme.textTheme.headlineMedium,
                            ),
                            Text(
                              '${pet.breed} • ${pet.gender.name}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pet.getAgeString(),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: AppIcons.journal,
                        label: 'Journal',
                        onTap: () => context.push('/journal?petId=${pet.id}'),
                      ),
                      _buildActionButton(
                        icon: AppIcons.reminders,
                        label: 'Reminders',
                        onTap: () => context.push('/reminders?petId=${pet.id}'),
                      ),
                      _buildActionButton(
                        icon: AppIcons.medication,
                        label: 'Meds',
                        onTap: () {
                          // TODO: Navigate to medications
                        },
                      ),
                      _buildActionButton(
                        icon: AppIcons.chart,
                        label: 'Health',
                        onTap: () => context.push('/home/pet/${pet.id}/analytics'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Pet photos
            if (pet.photoUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: PhotoGallery(
                  photos: pet.photoUrls,
                  onAddPhoto: () {
                    // TODO: Implement photo upload
                  },
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Pet information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pet Information',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InfoItem(
                              label: 'Weight',
                              value: pet.weight != null
                                  ? '${pet.weight} kg'
                                  : 'Not set',
                              icon: AppIcons.weight,
                            ),
                          ),
                          Expanded(
                            child: InfoItem(
                              label: 'Birthdate',
                              value: pet.birthdate != null
                                  ? '${pet.birthdate!.day}/${pet.birthdate!.month}/${pet.birthdate!.year}'
                                  : 'Unknown',
                              icon: AppIcons.calendar,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (pet.microchipId != null && pet.microchipId!.isNotEmpty)
                        InfoItem(
                          label: 'Microchip ID',
                          value: pet.microchipId!,
                          icon: Icons.memory,
                        ),
                      if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        InfoItem(
                          label: 'Notes',
                          value: pet.notes!,
                          icon: Icons.note,
                          multiline: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upcoming reminders
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HomeSection(
                title: 'Upcoming Reminders',
                onViewAll: () => context.push('/reminders?petId=${pet.id}'),
                child: reminders.when(
                  data: (reminderList) {
                    if (reminderList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No upcoming reminders',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reminderList.length > 3 ? 3 : reminderList.length,
                      itemBuilder: (context, index) {
                        final reminder = reminderList[index];
                        return ReminderCard(
                          reminder: reminder,
                          onTap: () {
                            // TODO: Navigate to reminder detail
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading reminders: $error'),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent journal entries
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HomeSection(
                title: 'Recent Journal Entries',
                onViewAll: () => context.push('/journal?petId=${pet.id}'),
                child: FutureBuilder<List<JournalEntryModel>>(
                  future: ref.read(journalProvider.notifier).getJournalEntries(
                    petId: pet.id,
                    limit: 3,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    
                    final entries = snapshot.data ?? [];
                    
                    if (entries.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No journal entries yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return RecentJournalCard(
                          entry: entry,
                          onTap: () {
                            context.push('/journal/entry/${entry.id}');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'health':
        // TODO: Navigate to health records
        break;
      case 'medication':
        // TODO: Navigate to medications
        break;
      case 'weight':
        // TODO: Navigate to weight history
        break;
      case 'share':
        // TODO: Implement share profile
        break;
      case 'qr':
        // TODO: Generate QR code
        break;
      case 'export':
        // TODO: Export pet data
        break;
      case 'lost':
        context.push('/home/pet/${widget.petId}/lost');
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: const Text(
          'Are you sure you want to delete this pet? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Delete pet
              final success = await ref.read(petsProvider.notifier).deletePet(widget.petId);
              
              if (success && mounted) {
                context.go('/home');
                
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pet deleted successfully'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}