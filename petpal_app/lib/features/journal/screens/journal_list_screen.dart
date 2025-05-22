import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/journal/models/journal_entry.dart';
import 'package:petpal/features/journal/providers/journal_provider.dart';
import 'package:petpal/features/journal/widgets/recent_journal_card.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/features/pets/widgets/pet_avatar.dart';
import 'package:petpal/widgets/loading_indicator.dart';
import 'package:petpal/widgets/empty_state.dart';
import 'package:petpal/widgets/error_view.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  String? _selectedPetId;
  JournalEntryType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFiltering = false;
  
  final _monthFormat = DateFormat('MMMM yyyy');
  
  @override
  void initState() {
    super.initState();
    // Load entries
    Future.microtask(() {
      ref.read(journalProvider.notifier).loadJournalEntries();
    });
  }
  
  void _toggleFilter() {
    setState(() {
      _isFiltering = !_isFiltering;
      
      // Clear filters when closing
      if (!_isFiltering) {
        _selectedPetId = null;
        _selectedType = null;
        _startDate = null;
        _endDate = null;
      }
    });
  }
  
  void _selectPet(String petId) {
    setState(() {
      _selectedPetId = petId;
    });
  }
  
  void _selectType(JournalEntryType type) {
    setState(() {
      _selectedType = _selectedType == type ? null : type;
    });
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );
    
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }
  
  List<JournalEntryModel> _filterEntries(List<JournalEntryModel> entries) {
    if (!_isFiltering) return entries;
    
    return entries.where((entry) {
      // Filter by pet
      if (_selectedPetId != null && entry.petId != _selectedPetId) {
        return false;
      }
      
      // Filter by type
      if (_selectedType != null && entry.entryType != _selectedType) {
        return false;
      }
      
      // Filter by date range
      if (_startDate != null && entry.timestamp.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null) {
        final endDateWithTime = _endDate!.add(const Duration(days: 1));
        if (entry.timestamp.isAfter(endDateWithTime)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entriesAsync = ref.watch(journalProvider);
    final petsAsync = ref.watch(petsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: Icon(_isFiltering ? Icons.filter_list_off : Icons.filter_list),
            onPressed: _toggleFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter options
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFiltering ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isFiltering ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet filter
                    Text(
                      'Filter by Pet',
                      style: theme.textTheme.titleMedium,
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
                    
                    // Entry type filter
                    Text(
                      'Filter by Type',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: JournalEntryType.values.map((type) {
                        final isSelected = _selectedType == type;
                        
                        IconData typeIcon;
                        switch (type) {
                          case JournalEntryType.food:
                            typeIcon = AppIcons.food;
                            break;
                          case JournalEntryType.activity:
                            typeIcon = AppIcons.activity;
                            break;
                          case JournalEntryType.health:
                            typeIcon = AppIcons.health;
                            break;
                          case JournalEntryType.mood:
                            typeIcon = AppIcons.neutral;
                            break;
                          case JournalEntryType.general:
                          default:
                            typeIcon = AppIcons.general;
                            break;
                        }
                        
                        return FilterChip(
                          label: Text(_getEntryTypeName(type)),
                          avatar: Icon(
                            typeIcon,
                            size: 18,
                          ),
                          selected: isSelected,
                          onSelected: (_) => _selectType(type),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date range filter
                    Text(
                      'Filter by Date',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? '${_monthFormat.format(_startDate!)} - ${_monthFormat.format(_endDate!)}'
                            : 'Select Date Range',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Clear filters
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedPetId = null;
                            _selectedType = null;
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Journal entries list
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final filteredEntries = _filterEntries(entries);
                
                if (filteredEntries.isEmpty) {
                  return EmptyState(
                    icon: AppIcons.journal,
                    title: _isFiltering
                        ? 'No matching entries'
                        : 'No journal entries yet',
                    message: _isFiltering
                        ? 'Try changing your filters or create new entries'
                        : 'Start tracking your pet\'s daily activities',
                    actionLabel: 'Add Entry',
                    actionRoute: '/journal/create',
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(journalProvider.notifier).loadJournalEntries(
                      forceRefresh: true,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      
                      // Show date header if this is the first entry or the date is different
                      final showDateHeader = index == 0 ||
                          !_isSameDay(
                            entry.timestamp,
                            filteredEntries[index - 1].timestamp,
                          );
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            if (index > 0) const SizedBox(height: 16),
                            _buildDateHeader(entry.timestamp),
                            const SizedBox(height: 8),
                          ],
                          RecentJournalCard(
                            entry: entry,
                            onTap: () {
                              context.push('/journal/entry/${entry.id}');
                            },
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                title: 'Error',
                message: 'Failed to load journal entries: $error',
                actionLabel: 'Retry',
                onAction: () {
                  ref.read(journalProvider.notifier).loadJournalEntries(
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
          context.push('/journal/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildDateHeader(DateTime date) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    String dateText;
    
    if (_isSameDay(date, today)) {
      dateText = 'Today';
    } else if (_isSameDay(date, yesterday)) {
      dateText = 'Yesterday';
    } else {
      final dateFormat = DateFormat.yMMMMd();
      dateText = dateFormat.format(date);
    }
    
    return Text(
      dateText,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  String _getEntryTypeName(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.food:
        return 'Food';
      case JournalEntryType.activity:
        return 'Activity';
      case JournalEntryType.health:
        return 'Health';
      case JournalEntryType.mood:
        return 'Mood';
      case JournalEntryType.general:
        return 'General';
    }
  }
}