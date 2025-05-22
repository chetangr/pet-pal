import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/analytics/providers/analytics_provider.dart';
import 'package:petpal/features/analytics/models/weight_record.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/widgets/loading_indicator.dart';
import 'package:petpal/widgets/error_view.dart';
import 'package:petpal/widgets/empty_state.dart';

class AnalyticsScreen extends ConsumerWidget {
  final String petId;
  
  const AnalyticsScreen({
    Key? key,
    required this.petId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final petAsync = ref.watch(petProvider(petId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Analytics'),
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
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet info header
                Row(
                  children: [
                    Text(
                      '${pet.name}\'s Health',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        _showAddWeightDialog(context, ref, pet.id);
                      },
                      child: const Text('Add Weight'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Weight history chart
                _buildWeightChart(context, ref),
                
                const SizedBox(height: 24),
                
                // Activity stats
                _buildActivityStats(context, ref),
                
                const SizedBox(height: 24),
                
                // Health observations from journal
                _buildHealthObservations(context, ref),
              ],
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
  
  Widget _buildWeightChart(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weightHistoryAsync = ref.watch(weightHistoryProvider(petId));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight History',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            weightHistoryAsync.when(
              data: (weightRecords) {
                if (weightRecords.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No weight records yet'),
                    ),
                  );
                }
                
                // Sort by date
                weightRecords.sort((a, b) => a.date.compareTo(b.date));
                
                // Prepare chart data
                final spots = weightRecords.asMap().entries.map((entry) {
                  final index = entry.key.toDouble();
                  final record = entry.value;
                  return FlSpot(index, record.weight);
                }).toList();
                
                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= weightRecords.length) {
                                    return const Text('');
                                  }
                                  
                                  final dateFormat = DateFormat('MM/dd');
                                  final date = weightRecords[index].date;
                                  return Text(
                                    dateFormat.format(date),
                                    style: theme.textTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toStringAsFixed(1)} kg',
                                    style: theme.textTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          minX: 0,
                          maxX: (weightRecords.length - 1).toDouble(),
                          minY: weightRecords.map((r) => r.weight).reduce((a, b) => a < b ? a : b) - 0.5,
                          maxY: weightRecords.map((r) => r.weight).reduce((a, b) => a > b ? a : b) + 0.5,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: colorScheme.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: colorScheme.primary,
                                    strokeWidth: 1,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Weight stats
                    _buildWeightStats(weightRecords),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeightStats(List<WeightRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();
    
    // Calculate stats
    final currentWeight = records.last.weight;
    
    double? weightChange;
    double? percentChange;
    
    if (records.length > 1) {
      final previousWeight = records[records.length - 2].weight;
      weightChange = currentWeight - previousWeight;
      percentChange = (weightChange / previousWeight) * 100;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Current',
          '$currentWeight kg',
          Icons.monitor_weight,
          Colors.blue,
        ),
        if (weightChange != null) ...[
          _buildStatItem(
            'Change',
            '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(2)} kg',
            weightChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            weightChange >= 0 ? Colors.red : Colors.green,
          ),
          _buildStatItem(
            'Percent',
            '${percentChange!.toStringAsFixed(1)}%',
            Icons.percent,
            percentChange >= 0 ? Colors.red : Colors.green,
          ),
        ],
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivityStats(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityAsync = ref.watch(activityAnalyticsProvider(petId));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Stats',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            activityAsync.when(
              data: (activity) {
                if (!activity.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No activity data yet'),
                    ),
                  );
                }
                
                // Calculate activity distribution
                final totalMinutes = activity.totalMinutes.toDouble();
                final pieData = <PieChartSectionData>[];
                
                final colors = [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                  Colors.indigo,
                ];
                
                int colorIndex = 0;
                activity.minutesByType.forEach((type, minutes) {
                  final percent = minutes / totalMinutes * 100;
                  pieData.add(
                    PieChartSectionData(
                      color: colors[colorIndex % colors.length],
                      value: minutes.toDouble(),
                      title: '$type\n${percent.toStringAsFixed(0)}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                  colorIndex++;
                });
                
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Activities',
                          '${activity.totalActivities}',
                          Icons.directions_run,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Total',
                          '${activity.totalMinutes} min',
                          Icons.timer,
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Avg',
                          '${activity.averageDuration.toStringAsFixed(0)} min',
                          Icons.av_timer,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (activity.minutesByType.isNotEmpty) ...[
                      Text(
                        'Activity Distribution',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: pieData,
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthObservations(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // This would need more journal analysis functionality
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Placeholder for health insights
            const EmptyState(
              icon: AppIcons.health,
              title: 'Coming Soon',
              message: 'AI-powered health insights will appear here as you add more data',
              iconSize: 48,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddWeightDialog(BuildContext context, WidgetRef ref, String petId) {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g., 12.5',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Date: ${DateFormat('MMM d, yyyy').format(selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                
                if (pickedDate != null) {
                  selectedDate = pickedDate;
                  // Force rebuild dialog
                  Navigator.pop(context);
                  _showAddWeightDialog(context, ref, petId);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., After breakfast',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (weightController.text.isEmpty) {
                return;
              }
              
              final weight = double.tryParse(weightController.text);
              if (weight == null || weight <= 0) {
                return;
              }
              
              final record = WeightRecord(
                id: '',
                petId: petId,
                weight: weight,
                date: selectedDate,
                notes: notesController.text.isEmpty ? null : notesController.text,
                createdBy: '',
                createdAt: DateTime.now(),
              );
              
              // Save weight record
              await ref.read(weightServiceProvider).addWeightRecord(record);
              
              // Refresh weight history
              ref.refresh(weightHistoryProvider(petId));
              
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}