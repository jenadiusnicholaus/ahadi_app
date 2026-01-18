import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../models/participant_model.dart';
import '../controllers/events_controller.dart';

class ParticipantsList extends StatelessWidget {
  final String eventId;
  final bool compact;
  final VoidCallback? onViewAll;
  final void Function(ParticipantModel participant)? onSendMessage;

  const ParticipantsList({
    super.key,
    required this.eventId,
    this.compact = false,
    this.onViewAll,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final eventsController = Get.find<EventsController>();

    return Obx(() {
      final participants = eventsController.participants
          .where((p) => p.eventId.toString() == eventId)
          .toList();

      if (participants.isEmpty) {
        return _buildEmptyState();
      }

      final displayedParticipants = compact
          ? participants.take(3).toList()
          : participants;

      return Container(
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
            _buildHeader(participants.length),
            const SizedBox(height: 16),
            _buildStatistics(participants),
            const SizedBox(height: 20),

            // Participants list
            ...displayedParticipants.map(
              (participant) => _buildParticipantCard(participant),
            ),

            if (compact && participants.length > 3) ...[
              const SizedBox(height: 12),
              _buildViewAllButton(participants.length - 3),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildHeader(int totalCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.people, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                '$totalCount member${totalCount == 1 ? '' : 's'} joined',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        if (compact && onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }

  Widget _buildStatistics(List<ParticipantModel> participants) {
    final confirmed = participants.where((p) => p.status == 'CONFIRMED').length;
    final pending = participants.where((p) => p.status == 'PENDING').length;
    final attended = participants
        .where((p) => p.status == 'CONFIRMED')
        .length; // Using CONFIRMED as attended for now

    return Row(
      children: [
        Expanded(child: _buildStatCard('Confirmed', confirmed, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Pending', pending, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Attended', attended, AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(ParticipantModel participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  participant.name.isNotEmpty
                      ? participant.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Participant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildStatusBadge(participant.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (participant.email.isNotEmpty)
                      Text(
                        participant.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Contributed: \$${participant.totalContributions.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Send Message Button
          if (onSendMessage != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onSendMessage!(participant),
                icon: Icon(
                  Icons.message_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Send Message',
                  style: TextStyle(color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        color = Colors.green;
        text = 'Confirmed';
        break;
      case 'PENDING':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'DECLINED':
        color = Colors.red;
        text = 'Declined';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildViewAllButton(int remainingCount) {
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View $remainingCount more participant${remainingCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(40),
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
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Participants Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite people to join this event',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
