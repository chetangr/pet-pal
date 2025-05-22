import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/features/pets/widgets/pet_avatar.dart';
import 'package:petpal/features/reminders/providers/reminder_provider.dart';
import 'package:petpal/features/reminders/widgets/reminder_card.dart';
import 'package:petpal/features/journal/widgets/recent_journal_card.dart';
import 'package:petpal/features/home/widgets/quick_stat_card.dart';
import 'package:petpal/features/home/widgets/home_section.dart';
import 'package:petpal/widgets/sync_status_indicator.dart';
import 'package:petpal/widgets/empty_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedPetId;
  
  @override
  void initState() {
    super.initState();
    // Initialize pets
    Future.microtask(() {
      ref.read(petsProvider.notifier).loadPets();
      ref.read(remindersProvider.notifier).loadReminders();
    });
  }
  
  void _selectPet(String petId) {
    setState(() {
      _selectedPetId = petId;
    });
    
    // Update reminders for selected pet
    ref.read(remindersProvider.notifier).loadReminders(petId: petId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final pets = ref.watch(petsProvider);
    final reminders = ref.watch(upcomingRemindersProvider);
    
    // Get selected pet or first pet
    final selectedPet = pets.when(
      data: (petList) {
        if (petList.isEmpty) return null;
        
        if (_selectedPetId == null) {
          // Auto-select first pet
          _selectedPetId = petList.first.id;
          return petList.first;
        }
        
        // Find selected pet
        return petList.firstWhere(
          (pet) => pet.id == _selectedPetId, 
          orElse: () => petList.first,
        );
      },
      loading: () => null,
      error: (_, __) => null,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.displayName.split(' ').first ?? 'there'}!',
              style: theme.textTheme.titleLarge,
            ),
            const SyncStatusIndicator(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.notification),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh pets and reminders
          await ref.read(petsProvider.notifier).loadPets(forceRefresh: true);
          await ref.read(remindersProvider.notifier).loadReminders(
            forceRefresh: true,
            petId: _selectedPetId,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet selector
              _buildPetSelector(pets),
              
              if (pets.asData?.value.isEmpty ?? true)
                const EmptyState(
                  icon: AppIcons.addPet,
                  title: 'No pets yet',
                  message: 'Add your first pet to get started',
                  actionLabel: 'Add Pet',
                  actionRoute: '/home/add-pet',
                )
              else if (selectedPet != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected pet info
                      _buildSelectedPetHeader(selectedPet),
                      
                      // Quick stats
                      _buildQuickStats(selectedPet),
                      
                      // Upcoming reminders
                      _buildUpcomingReminders(reminders, selectedPet.id),
                      
                      // Recent journal entries
                      _buildRecentJournalEntries(selectedPet.id),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPetSelector(AsyncValue<List<PetModel>> pets) {
    return pets.when(
      data: (petList) {
        if (petList.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: 120,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: petList.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              // Add pet button at the end
              if (index == petList.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => context.push('/home/add-pet'),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Pet',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                );
              }
              
              // Pet avatar
              final pet = petList[index];
              final isSelected = pet.id == _selectedPetId;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _selectPet(pet.id),
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        children: [
                          PetAvatar(
                            pet: pet,
                            size: 60,
                            isSelected: isSelected,
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
        child: Text('Error loading pets: $error'),
      ),
    );
  }
  
  Widget _buildSelectedPetHeader(PetModel pet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          PetAvatar(pet: pet, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  pet.getAgeString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.edit),
            onPressed: () {
              context.push('/home/pet/${pet.id}/edit');
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickStats(PetModel pet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
        children: [
          QuickStatCard(
            icon: AppIcons.weight,
            label: 'Weight',
            value: pet.weight != null ? '${pet.weight} kg' : 'Add',
            onTap: () {
              // TODO: Open weight tracking
            },
          ),
          QuickStatCard(
            icon: AppIcons.medication,
            label: 'Medications',
            value: '${pet.medications?.length ?? 0}',
            onTap: () {
              // TODO: Open medications
            },
          ),
          QuickStatCard(
            icon: AppIcons.calendar,
            label: 'Next Vet',
            value: 'In 15d',
            onTap: () {
              // TODO: Open vet appointments
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpcomingReminders(AsyncValue<List<ReminderModel>> reminders, String petId) {
    return HomeSection(
      title: 'Upcoming Reminders',
      onViewAll: () => context.push('/reminders'),
      child: reminders.when(
        data: (reminderList) {
          if (reminderList.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No upcoming reminders',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  // TODO: Open reminder detail
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
    );
  }
  
  Widget _buildRecentJournalEntries(String petId) {
    return HomeSection(
      title: 'Recent Journal Entries',
      onViewAll: () => context.push('/journal'),
      child: FutureBuilder<List<JournalEntryModel>>(
        future: ref.read(journalProvider.notifier).getJournalEntries(
          petId: petId,
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
              child: Text('Error loading journal entries: ${snapshot.error}'),
            );
          }
          
          final entries = snapshot.data ?? [];
          
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No journal entries yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
    );
  }
}