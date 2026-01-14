import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final bool showActions;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onShare,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            _buildCoverImage(),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Type & Status badges
                  _buildBadges(),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    event.title,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Date & Location
                  if (event.startDate != null) ...[
                    _buildInfoRow(
                      Icons.calendar_today,
                      _formatDate(event.startDate!),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (event.location.isNotEmpty)
                    _buildInfoRow(Icons.location_on, event.location),

                  // Progress bar (if has target)
                  if (event.contributionTarget != null &&
                      event.contributionTarget! > 0) ...[
                    const SizedBox(height: 12),
                    _buildProgressSection(),
                  ],

                  // Actions
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    _buildActionButtons(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final imageUrl = event.displayCoverImage;

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1)),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEventTypeIcon(),
            size: 48,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            event.eventType?.name ?? 'Event',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventTypeIcon() {
    final slug = event.eventType?.slug ?? '';
    switch (slug) {
      case 'wedding':
        return Icons.favorite;
      case 'fundraiser':
        return Icons.volunteer_activism;
      case 'church':
        return Icons.church;
      case 'graduation':
        return Icons.school;
      case 'birthday':
        return Icons.cake;
      case 'memorial':
        return Icons.local_florist;
      default:
        return Icons.event;
    }
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Event type badge
        if (event.eventType != null)
          _buildBadge(
            event.eventType!.name,
            AppColors.primary.withOpacity(0.1),
            AppColors.primary,
          ),

        // Status badge
        _buildStatusBadge(),

        // Visibility badge
        if (event.visibility != 'PRIVATE')
          _buildBadge(
            event.visibilityDisplay,
            Colors.blue.withOpacity(0.1),
            Colors.blue,
          ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;

    switch (event.status) {
      case 'ACTIVE':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'COMPLETED':
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        break;
      case 'CANCELLED':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default: // DRAFT
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
    }

    return _buildBadge(event.statusDisplay, bgColor, textColor);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final progress = event.progressPercentage;
    final collected = event.totalContributions;
    final target = event.contributionTarget ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${event.currency} ${_formatAmount(collected)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'of ${event.currency} ${_formatAmount(target)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (progress / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 100 ? Colors.green : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.toStringAsFixed(0)}% funded',
              style: AppTextStyles.caption,
            ),
            Text(
              '${event.participantCount} participants',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
