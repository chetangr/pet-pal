import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/reminders/models/reminder.dart';
import 'package:petpal/features/reminders/providers/reminder_provider.dart';
import 'package:petpal/features/reminders/widgets/reminder_card.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/features/pets/widgets/pet_avatar.dart';
import 'package:petpal/widgets/loading_indicator.dart';
import 'package:petpal/widgets/empty_state.dart';
import 'package:petpal/widgets/error_view.dart';

class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> with TickerProviderStateMixin {
  String? _selectedPetId;
  ReminderType? _selectedType;
  bool _showCompleted = false;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {
        _showCompleted = _tabController.index == 1;
      });
    });
    
    // Load reminders
    Future.microtask(() {
      ref.read(remindersProvider.notifier).loadReminders();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _selectPet(String? petId) {
    setState(() {
      _selectedPetId = petId == _selectedPetId ? null : petId;
    });
  }
  
  void _selectType(ReminderType? type) {
    setState(() {
      _selectedType = type == _selectedType ? null : type;
    });
  }
  
  List<ReminderModel> _filterReminders(List<ReminderModel> reminders) {
    return reminders.where((reminder) {
      // Filter by completion status
      if (_showCompleted && !reminder.completed) return false;
      if (!_showCompleted && reminder.completed) return false;
      
      // Filter by pet
      if (_selectedPetId != null && reminder.petId != _selectedPetId) return false;
      
      // Filter by type
      if (_selectedType != null && reminder.reminderType != _selectedType) return false;
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final petsAsync = ref.watch(petsProvider);
    final remindersAsync = ref.watch(remindersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet filter
                Text(
                  'Filter by Pet',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                petsAsync.when(
                  data: (pets) {
                    if (pets.isEmpty) {
                      return const Text('No pets available');
                    }
                    
                    return SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          final isSelected = pet.id == _selectedPetId;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () => _selectPet(pet.id),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      PetAvatar(
                                        pet: pet,
                                        size: 50,
                                        isSelected: isSelected,
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pet.name,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: isSelected ? colorScheme.primary : null,
                                      fontWeight: isSelected ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const Text('Error loading pets'),
                ),
                
                const SizedBox(height: 16),
                
                // Type filter
                Text(
                  'Filter by Type',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTypeChip(ReminderType.medication, 'Medication'),
                      _buildTypeChip(ReminderType.food, 'Food'),
                      _buildTypeChip(ReminderType.water, 'Water'),
                      _buildTypeChip(ReminderType.walk, 'Walk'),
                      _buildTypeChip(ReminderType.vet, 'Vet'),
                      _buildTypeChip(ReminderType.grooming, 'Grooming'),
                      _buildTypeChip(ReminderType.vaccination, 'Vaccination'),
                      _buildTypeChip(ReminderType.other, 'Other'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Reminder list
          Expanded(
            child: remindersAsync.when(
              data: (reminders) {
                final filteredReminders = _filterReminders(reminders);
                
                if (filteredReminders.isEmpty) {
                  return EmptyState(
                    icon: AppIcons.reminders,
                    title: _showCompleted 
                        ? 'No completed reminders' 
                        : 'No active reminders',
                    message: _showCompleted
                        ? 'Completed reminders will appear here'
                        : 'Add reminders to track medications, vet appointments, and more',
                    actionLabel: _showCompleted ? null : 'Add Reminder',
                    actionRoute: _showCompleted ? null : '/reminders/create',
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(remindersProvider.notifier).loadReminders(
                      forceRefresh: true,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = filteredReminders[index];
                      
                      return ReminderCard(
                        reminder: reminder,
                        onTap: () {
                          // TODO: Navigate to reminder detail
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                title: 'Error',
                message: 'Failed to load reminders: $error',
                actionLabel: 'Retry',
                onAction: () {
                  ref.read(remindersProvider.notifier).loadReminders(
                    forceRefresh: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/reminders/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildTypeChip(ReminderType type, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedType == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _selectType(type),
        avatar: Icon(
          ReminderModel.getIcon(type),
          size: 18,
          color: isSelected 
              ? colorScheme.onPrimary 
              : colorScheme.primary,
        ),
      ),
    );
  }
}