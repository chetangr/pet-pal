import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petpal/features/reminders/models/reminder.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/features/reminders/providers/reminder_provider.dart';

class ReminderCard extends ConsumerWidget {
  final ReminderModel reminder;
  final VoidCallback? onTap;
  final bool showPetInfo;
  final bool showActions;
  
  const ReminderCard({
    Key? key,
    required this.reminder,
    this.onTap,
    this.showPetInfo = true,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('E, MMM d, y');
    
    // Get icon and color based on reminder type
    final IconData reminderIcon = ReminderModel.getIcon(reminder.reminderType);
    
    // Calculate background color based on status and type
    Color backgroundColor;
    Color iconColor;
    
    if (reminder.completed) {
      backgroundColor = colorScheme.surfaceVariant.withOpacity(0.5);
      iconColor = colorScheme.onSurfaceVariant.withOpacity(0.7);
    } else if (reminder.isOverdue(DateTime.now())) {
      backgroundColor = colorScheme.errorContainer.withOpacity(0.2);
      iconColor = colorScheme.error;
    } else {
      switch (reminder.reminderType) {
        case ReminderType.medication:
          backgroundColor = Colors.blue.withOpacity(0.1);
          iconColor = Colors.blue;
          break;
        case ReminderType.food:
          backgroundColor = Colors.orange.withOpacity(0.1);
          iconColor = Colors.orange;
          break;
        case ReminderType.water:
          backgroundColor = Colors.lightBlue.withOpacity(0.1);
          iconColor = Colors.lightBlue;
          break;
        case ReminderType.walk:
          backgroundColor = Colors.green.withOpacity(0.1);
          iconColor = Colors.green;
          break;
        case ReminderType.vet:
          backgroundColor = Colors.red.withOpacity(0.1);
          iconColor = Colors.red;
          break;
        case ReminderType.grooming:
          backgroundColor = Colors.purple.withOpacity(0.1);
          iconColor = Colors.purple;
          break;
        case ReminderType.vaccination:
          backgroundColor = Colors.teal.withOpacity(0.1);
          iconColor = Colors.teal;
          break;
        case ReminderType.other:
        default:
          backgroundColor = colorScheme.primaryContainer.withOpacity(0.1);
          iconColor = colorScheme.primary;
          break;
      }
    }
    
    final petAsync = reminder.petId != null 
        ? ref.watch(petProvider(reminder.petId!))
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      reminderIcon,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Reminder details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: reminder.completed 
                                ? TextDecoration.lineThrough 
                                : null,
                            color: reminder.completed
                                ? colorScheme.onSurface.withOpacity(0.7)
                                : null,
                          ),
                        ),
                        
                        // Time info
                        Text(
                          '${timeFormat.format(reminder.startTime)} - ${dateFormat.format(reminder.startTime)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        
                        // Recurrence info if applicable
                        if (reminder.isRecurring) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Repeats: ${RecurrenceHelper.getDescription(reminder.recurrenceRule!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        
                        // Pet info
                        if (showPetInfo && reminder.petId != null) ...[
                          const SizedBox(height: 4),
                          petAsync?.when(
                            data: (pet) {
                              if (pet == null) return const SizedBox.shrink();
                              
                              return Text(
                                'For: ${pet.name}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                            loading: () => const SizedBox(
                              width: 80,
                              height: 12,
                              child: LinearProgressIndicator(
                                minHeight: 2,
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ) ?? const SizedBox.shrink(),
                        ],
                        
                        // Description if available
                        if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            reminder.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: reminder.completed
                                  ? colorScheme.onSurface.withOpacity(0.5)
                                  : colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  if (reminder.completed)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary.withOpacity(0.5),
                      size: 20,
                    )
                  else if (reminder.isOverdue(DateTime.now()))
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.error,
                      size: 20,
                    ),
                ],
              ),
              
              // Action buttons
              if (showActions && !reminder.completed) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Snooze button
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(remindersProvider.notifier)
                            .snoozeReminder(reminder.id);
                      },
                      icon: const Icon(Icons.snooze, size: 16),
                      label: const Text('Snooze'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Complete button
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(remindersProvider.notifier)
                            .completeReminder(reminder.id);
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ] else if (showActions && reminder.completed) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(remindersProvider.notifier)
                            .uncompleteReminder(reminder.id);
                      },
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Undo'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}