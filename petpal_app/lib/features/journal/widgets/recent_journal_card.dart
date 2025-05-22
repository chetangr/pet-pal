import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/journal/models/journal_entry.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecentJournalCard extends StatelessWidget {
  final JournalEntryModel entry;
  final VoidCallback? onTap;
  
  const RecentJournalCard({
    Key? key,
    required this.entry,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    
    // Get icon based on entry type
    IconData entryIcon;
    Color iconColor;
    
    switch (entry.entryType) {
      case JournalEntryType.food:
        entryIcon = AppIcons.food;
        iconColor = Colors.orange;
        break;
      case JournalEntryType.activity:
        entryIcon = AppIcons.activity;
        iconColor = Colors.green;
        break;
      case JournalEntryType.health:
        entryIcon = AppIcons.health;
        iconColor = Colors.red;
        break;
      case JournalEntryType.mood:
        entryIcon = _getMoodIcon(entry.moodData?.moodName);
        iconColor = Colors.purple;
        break;
      case JournalEntryType.general:
      default:
        entryIcon = AppIcons.general;
        iconColor = Colors.blue;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      entryIcon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.getTitle(),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(entry.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Entry details
              _buildEntryDetails(context),
              
              // Photos
              if (entry.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.photoUrls.length > 3 ? 3 : entry.photoUrls.length,
                    itemBuilder: (context, index) {
                      final isLastItem = index == 2 && entry.photoUrls.length > 3;
                      
                      if (isLastItem) {
                        // Show "more" indicator
                        return Stack(
                          children: [
                            _buildPhotoThumbnail(entry.photoUrls[index]),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '+${entry.photoUrls.length - 3}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      return _buildPhotoThumbnail(entry.photoUrls[index]);
                    },
                  ),
                ),
              ],
              
              // Tags
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEntryDetails(BuildContext context) {
    final theme = Theme.of(context);
    
    // Build details based on entry type
    switch (entry.entryType) {
      case JournalEntryType.food:
        if (entry.foodData == null) {
          return _buildNotesSection(context);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Food',
                    entry.foodData!.foodName,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Amount',
                    entry.foodData!.amount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Meal',
                    entry.foodData!.mealType,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Finished',
                    entry.foodData!.finished ? 'Yes' : 'No',
                  ),
                ),
              ],
            ),
            
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotesSection(context),
            ],
          ],
        );
        
      case JournalEntryType.activity:
        if (entry.activityData == null) {
          return _buildNotesSection(context);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Activity',
                    entry.activityData!.activityType,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Duration',
                    '${entry.activityData!.duration} mins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Intensity',
                    entry.activityData!.intensity,
                  ),
                ),
                if (entry.activityData!.distance != null)
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Distance',
                      '${entry.activityData!.distance} km',
                    ),
                  ),
              ],
            ),
            
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotesSection(context),
            ],
          ],
        );
        
      case JournalEntryType.health:
        if (entry.healthData == null) {
          return _buildNotesSection(context);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Symptom',
                    entry.healthData!.symptom,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Severity',
                    entry.healthData!.severity,
                  ),
                ),
              ],
            ),
            
            if (entry.healthData!.medicationGiven) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Medication',
                      entry.healthData!.medicationName ?? 'Given',
                    ),
                  ),
                  if (entry.healthData!.medicationDosage != null)
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        'Dosage',
                        entry.healthData!.medicationDosage!,
                      ),
                    ),
                ],
              ),
            ],
            
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotesSection(context),
            ],
          ],
        );
        
      case JournalEntryType.mood:
        if (entry.moodData == null) {
          return _buildNotesSection(context);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Mood',
                    entry.moodData!.moodName,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Energy',
                    entry.moodData!.energyLevel,
                  ),
                ),
              ],
            ),
            
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotesSection(context),
            ],
          ],
        );
        
      case JournalEntryType.general:
      default:
        return _buildNotesSection(context);
    }
  }
  
  Widget _buildDetailItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildNotesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (entry.notes == null || entry.notes!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          entry.notes!,
          style: theme.textTheme.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildPhotoThumbnail(String photoUrl) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.error,
            size: 20,
          ),
        ),
      ),
    );
  }
  
  IconData _getMoodIcon(String? mood) {
    if (mood == null) return AppIcons.neutral;
    
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return AppIcons.excited;
      case 'relaxed':
      case 'calm':
        return AppIcons.happy;
      case 'sad':
      case 'depressed':
        return AppIcons.sad;
      case 'angry':
      case 'aggressive':
        return AppIcons.angry;
      case 'sick':
      case 'unwell':
        return AppIcons.sick;
      default:
        return AppIcons.neutral;
    }
  }
}