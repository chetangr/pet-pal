import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';

class ScaffoldWithBottomNav extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithBottomNav({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<ScaffoldWithBottomNav> createState() => _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends ConsumerState<ScaffoldWithBottomNav> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).location;
    
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/journal')) {
      return 1;
    }
    if (location.startsWith('/reminders')) {
      return 2;
    }
    if (location.startsWith('/store')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/journal');
        break;
      case 2:
        context.go('/reminders');
        break;
      case 3:
        context.go('/store');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider);
    final selectedIndex = _calculateSelectedIndex(context);
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => _onItemTapped(index, context),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(AppIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.journal),
                label: 'Journal',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.reminders),
                label: 'Reminders',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.store),
                label: 'Store',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.more),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show quick actions based on the current tab
          _showQuickActions(context, selectedIndex);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  void _showQuickActions(BuildContext context, int currentIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildQuickActionSheet(context, currentIndex);
      },
    );
  }
  
  Widget _buildQuickActionSheet(BuildContext context, int currentIndex) {
    final theme = Theme.of(context);
    
    // Different actions based on the current tab
    List<QuickAction> actions = [];
    
    switch (currentIndex) {
      case 0: // Home
        actions = [
          QuickAction(
            icon: AppIcons.addPet,
            label: 'Add Pet',
            onTap: () {
              Navigator.pop(context);
              context.push('/home/add-pet');
            },
          ),
          QuickAction(
            icon: AppIcons.scan,
            label: 'Scan Barcode',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement barcode scanning
            },
          ),
        ];
        break;
      case 1: // Journal
        actions = [
          QuickAction(
            icon: AppIcons.addEntry,
            label: 'New Entry',
            onTap: () {
              Navigator.pop(context);
              context.push('/journal/create');
            },
          ),
          QuickAction(
            icon: AppIcons.photo,
            label: 'Add Photo',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement photo adding
            },
          ),
        ];
        break;
      case 2: // Reminders
        actions = [
          QuickAction(
            icon: AppIcons.addReminder,
            label: 'New Reminder',
            onTap: () {
              Navigator.pop(context);
              context.push('/reminders/create');
            },
          ),
          QuickAction(
            icon: AppIcons.medication,
            label: 'Add Medication',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement medication adding
            },
          ),
        ];
        break;
      default:
        actions = [
          QuickAction(
            icon: AppIcons.addPet,
            label: 'Add Pet',
            onTap: () {
              Navigator.pop(context);
              context.push('/home/add-pet');
            },
          ),
        ];
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions.map((action) => _buildActionItem(action)).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionItem(QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              action.icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}