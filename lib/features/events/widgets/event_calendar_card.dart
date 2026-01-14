import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/event_model.dart';

class EventCalendarCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onTap;

  const EventCalendarCard({
    super.key,
    required this.event,
    this.onAddToCalendar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Dates and reminders',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onAddToCalendar,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add to Calendar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Event dates
          _buildDateRow(
            'Start Date',
            event.startDate,
            Icons.play_circle_outline,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDateRow(
            'End Date', 
            event.endDate,
            Icons.stop_circle_outlined,
            Colors.red,
          ),
          
          const SizedBox(height: 16),
          
          // Duration info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _calculateDuration(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Time remaining
          _buildTimeRemaining(),
        ],
      ),
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime? date, IconData icon, Color color) {
    if (date == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, MMM d, y • h:mm a').format(date),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRemaining() {
    if (event.startDate == null) {
      return _buildStatusContainer('Date not set', Colors.grey, Icons.event_busy);
    }
    
    final now = DateTime.now();
    final difference = event.startDate!.difference(now);
    
    if (difference.isNegative) {
      // Event has started or ended
      final endDifference = event.endDate?.difference(now);
      if (endDifference != null && endDifference.isNegative) {
        return _buildStatusContainer('Event Ended', Colors.grey, Icons.event_busy);
      } else {
        return _buildStatusContainer('Event Live', Colors.green, Icons.live_tv);
      }
    } else {
      // Event hasn't started
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      
      String timeText;
      if (days > 0) {
        timeText = '$days day${days == 1 ? '' : 's'} remaining';
      } else if (hours > 0) {
        timeText = '$hours hour${hours == 1 ? '' : 's'} remaining';
      } else {
        timeText = '$minutes minute${minutes == 1 ? '' : 's'} remaining';
      }
      
      return _buildStatusContainer(timeText, AppColors.primary, Icons.schedule);
    }
  }
  
  Widget _buildStatusContainer(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    if (event.endDate == null || event.startDate == null) {
      return 'No duration set';
    }
    
    final difference = event.endDate!.difference(event.startDate!);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'}${hours > 0 ? ' $hours hour${hours == 1 ? '' : 's'}' : ''}';
    } else if (hours > 0) {
      final minutes = difference.inMinutes % 60;
      return '$hours hour${hours == 1 ? '' : 's'}${minutes > 0 ? ' $minutes min' : ''}';
    } else {
      return '${difference.inMinutes} minutes';
    }
  }
}