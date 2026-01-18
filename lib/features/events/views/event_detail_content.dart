import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../models/invitation_card_template_model.dart';
import '../models/participant_model.dart';
import '../../payments/views/event_wallet_screen.dart';
import '../../payments/views/event_transactions_screen.dart';
import 'invitation_templates_screen.dart';

/// Event detail content - renders inside DashboardShell
class EventDetailContent extends StatefulWidget {
  final EventModel event;
  final VoidCallback onContributionsTap;
  final VoidCallback onParticipantsTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onContributeTap;

  const EventDetailContent({
    super.key,
    required this.event,
    required this.onContributionsTap,
    required this.onParticipantsTap,
    this.onEditTap,
    this.onContributeTap,
  });

  @override
  State<EventDetailContent> createState() => _EventDetailContentState();
}

class _EventDetailContentState extends State<EventDetailContent> {
  final EventsController controller = Get.find<EventsController>();

  @override
  void initState() {
    super.initState();
    controller.loadEventDetail(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final event = controller.currentEvent.value ?? widget.event;
      
      // Debug logging
      debugPrint('📱 [EventDetailContent] Building with event ID: ${event.id}');
      debugPrint('📱 [EventDetailContent] currentEvent.value: ${controller.currentEvent.value?.id}');
      debugPrint('📱 [EventDetailContent] Template: ${event.invitationCardTemplate?.name}');
      debugPrint('📱 [EventDetailContent] Template ID: ${event.invitationCardTemplateId}');

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            _buildHeader(context, event),
            const SizedBox(height: 24),

            // Main content (mobile only)
            _buildMobileContent(context, event),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(
    BuildContext context,
    EventModel event,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(event.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (event.eventType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.eventType!.name,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (event.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context, EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image
        if (event.displayCoverImage.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(event.displayCoverImage, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 16),

        _buildProgressCard(event),
        const SizedBox(height: 16),

        // Quick actions
        _buildMobileQuickActions(event),
        const SizedBox(height: 16),

        // Invitation Template Section (for wedding events)
        if (event.isWedding) _buildInvitationTemplateSection(event),
        if (event.isWedding) const SizedBox(height: 16),

        _buildAboutSection(event),
        const SizedBox(height: 16),

        _buildDetailsCard(event),
        const SizedBox(height: 16),

        _buildParticipantsSection(event),
      ],
    );
  }

  Widget _buildProgressCard(EventModel event) {
    if (event.contributionTarget == null || event.contributionTarget == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TZS ${_formatAmount(event.totalContributions)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of TZS ${_formatAmount(event.contributionTarget!)} target',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${event.progressPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (event.progressPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${event.participantCount} participants',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onContributionsTap,
                  child: const Text('View all contributions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(EventModel event) {
    if (event.description.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Build invitation template section for wedding events
  Widget _buildInvitationTemplateSection(EventModel event) {
    final template = event.invitationCardTemplate;
    final customInvitationImage = event.customInvitationImage;
    
    // Debug logging
    debugPrint('🎨 [InvitationSection] Event ID: ${event.id}');
    debugPrint('🎨 [InvitationSection] Template: $template');
    debugPrint('🎨 [InvitationSection] Template ID: ${event.invitationCardTemplateId}');
    debugPrint('🎨 [InvitationSection] Custom Image: $customInvitationImage');
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.pink.shade400, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Invitation Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Upload custom option
                TextButton.icon(
                  onPressed: () => _uploadCustomInvitation(event),
                  icon: Icon(Icons.upload, size: 16, color: Colors.pink.shade600),
                  label: Text('Upload Custom', style: TextStyle(fontSize: 12, color: Colors.pink.shade600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show custom uploaded image if available
            if (customInvitationImage != null && customInvitationImage.isNotEmpty) ...[
              _buildCustomInvitationPreview(event, customInvitationImage),
            ] else if (template != null) ...[
              // Show selected template preview
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade200, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      // Always use styled preview for better consistency
                      child: _buildCanvasTemplatePreview(template),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  template.categoryDisplay,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _changeTemplate(event),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.pink.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // No template selected
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: Column(
                  children: [
                    Icon(Icons.style_outlined, size: 40, color: Colors.pink.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No template selected',
                      style: TextStyle(
                        color: Colors.pink.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a beautiful template for your wedding invitations',
                      style: TextStyle(color: Colors.pink.shade400, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _changeTemplate(event),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Select Template'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build canvas template preview
  Widget _buildCanvasTemplatePreview(InvitationCardTemplateModel template) {
    final primaryColor = _parseTemplateColor(template.primaryColor);
    final secondaryColor = _parseTemplateColor(template.secondaryColor);
    final accentColor = _parseTemplateColor(template.accentColor);
    final style = template.canvasStyle ?? 'elegant';
    
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor, accentColor.withValues(alpha: 0.95)],
        ),
      ),
      child: Stack(
        children: [
          if (style == 'floral') ...[
            Positioned(top: 12, left: 12, child: Text('🌸', style: TextStyle(fontSize: 20))),
            Positioned(top: 12, right: 12, child: Text('🌺', style: TextStyle(fontSize: 20))),
            Positioned(bottom: 12, left: 12, child: Text('🌺', style: TextStyle(fontSize: 20))),
            Positioned(bottom: 12, right: 12, child: Text('🌸', style: TextStyle(fontSize: 20))),
          ],
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 2),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WEDDING INVITATION',
                  style: TextStyle(
                    color: secondaryColor.withValues(alpha: 0.6),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Names Here',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Container(width: 50, height: 2, color: primaryColor),
                const SizedBox(height: 10),
                Text(
                  template.name,
                  style: TextStyle(
                    color: secondaryColor.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                template.categoryDisplay,
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build custom invitation preview
  Widget _buildCustomInvitationPreview(EventModel event, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Colors.pink.shade50,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Custom',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Invitation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Your uploaded design',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _removeCustomInvitation(event),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Upload custom invitation image
  Future<void> _uploadCustomInvitation(EventModel event) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (image != null) {
      try {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final ext = image.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final imageData = 'data:$mimeType;base64,$base64Image';

        await controller.updateEvent(event.id, {'custom_invitation_image': imageData});
        await controller.loadEventDetail(event.id);
        if (mounted) setState(() {});
        
        Get.snackbar(
          'Success',
          'Custom invitation uploaded successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to upload image: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Remove custom invitation
  Future<void> _removeCustomInvitation(EventModel event) async {
    try {
      await controller.updateEvent(event.id, {'custom_invitation_image': ''});
      await controller.loadEventDetail(event.id);
      if (mounted) setState(() {});
      
      Get.snackbar(
        'Removed',
        'Custom invitation removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Build template fallback when image fails
  Widget _buildTemplateFallback(InvitationCardTemplateModel template, double height) {
    return Container(
      height: height,
      color: _parseTemplateColor(template.primaryColor),
      child: const Center(
        child: Icon(Icons.card_giftcard, size: 40, color: Colors.white),
      ),
    );
  }

  /// Parse template hex color
  Color _parseTemplateColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Navigate to template selection and update event
  Future<void> _changeTemplate(EventModel event) async {
    debugPrint('🎨 Opening template selection for event ${event.id}');
    final result = await Get.to<InvitationCardTemplateModel>(
      () => const InvitationTemplatesScreen(),
      arguments: {
        'selectionMode': true,
        'selectedTemplateId': event.invitationCardTemplateId,
        'eventId': event.id,
        'eventTitle': event.title,
      },
    );

    debugPrint('🎨 Template selection result: ${result?.name} (ID: ${result?.id})');
    
    if (result != null) {
      // Update the event with new template
      try {
        debugPrint('🎨 Updating event ${event.id} with template ${result.id}');
        final success = await controller.updateEventTemplate(event.id, result.id);
        debugPrint('🎨 Update result: $success');
        // Refresh event data to show updated template
        await controller.loadEventDetail(event.id);
        debugPrint('🎨 Event reloaded, template: ${controller.currentEvent.value?.invitationCardTemplate?.name}');
        // Force UI rebuild
        if (mounted) setState(() {});
        Get.snackbar(
          'Success',
          'Invitation template updated to ${result.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        debugPrint('🎨 Error updating template: $e');
        Get.snackbar(
          'Error',
          'Failed to update template: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      debugPrint('🎨 No template selected (result was null)');
    }
  }

  Widget _buildDetailsCard(EventModel event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (event.startDate != null)
              _buildDetailRow(
                Icons.calendar_today,
                'Start Date',
                DateFormat('EEEE, MMMM d, y').format(event.startDate!),
              ),
            if (event.endDate != null)
              _buildDetailRow(
                Icons.event,
                'End Date',
                DateFormat('EEEE, MMMM d, y').format(event.endDate!),
              ),
            if (event.location.isNotEmpty)
              _buildDetailRow(Icons.location_on, 'Location', event.location),
            if (event.venueName.isNotEmpty)
              _buildDetailRow(Icons.place, 'Venue', event.venueName),
            _buildDetailRow(
              Icons.visibility,
              'Visibility',
              event.visibilityDisplay,
            ),
            if (event.joinCode.isNotEmpty)
              _buildDetailRow(
                Icons.qr_code,
                'Join Code',
                event.joinCode,
                onTap: () => _copyJoinCode(event),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(EventModel event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              Icons.payments,
              'View Contributions',
              widget.onContributionsTap,
            ),
            _buildActionButton(
              Icons.people,
              'Manage Participants',
              widget.onParticipantsTap,
            ),
            if (widget.onEditTap != null)
              _buildActionButton(Icons.edit, 'Edit Event', widget.onEditTap!),
            _buildActionButton(
              Icons.share,
              'Share Event',
              () => _shareEvent(event),
            ),
            if (event.chatEnabled)
              _buildActionButton(Icons.chat, 'Open Chat', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileQuickActions(EventModel event) {
    // Check if current user is the event owner
    final currentUserId = Get.find<StorageService>().getUser()?['id'] ?? 0;
    final isOwner = event.ownerId == currentUserId;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMobileActionTile(
                Icons.payments,
                'Contributions',
                widget.onContributionsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileActionTile(
                Icons.people,
                'Participants',
                widget.onParticipantsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileActionTile(
                Icons.share,
                'Share',
                () => _shareEvent(event),
              ),
            ),
          ],
        ),
        // Only show Wallet, Transactions, Edit for event owner
        if (isOwner) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileActionTile(
                  Icons.account_balance_wallet,
                  'Wallet',
                  () => Get.to(() => EventWalletScreen(event: event)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileActionTile(
                  Icons.receipt_long,
                  'Transactions',
                  () => Get.to(() => EventTransactionsScreen(event: event)),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.onEditTap != null)
                Expanded(
                  child: _buildMobileActionTile(
                    Icons.edit,
                    'Edit Event',
                    widget.onEditTap!,
                  ),
                )
              else
                Expanded(child: Container()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMobileActionTile(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(EventModel event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: widget.onParticipantsTap,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final participants = controller.participants.take(5).toList();
              if (participants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No participants yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return Column(
                children: participants
                    .map((p) => _buildParticipantTile(p))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTile(ParticipantModel participant) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(
          participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        participant.name.isNotEmpty ? participant.name : 'Anonymous',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'TZS ${_formatAmount(participant.totalContributions)}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _getParticipantStatusColor(
            participant.status,
          ).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          participant.statusDisplay,
          style: TextStyle(
            fontSize: 11,
            color: _getParticipantStatusColor(participant.status),
          ),
        ),
      ),
    );
  }

  void _shareEvent(EventModel event) {
    final shareText =
        '''
🎉 You're invited to "${event.title}"!

Join using code: ${event.joinCode}

Powered by Ahadi - Event Contributions Made Easy
''';

    // On mobile, use native share
    Share.share(shareText, subject: 'Join ${event.title}');
  }

  void _showShareDialog(EventModel event, String shareLink, String shareText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.share, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Share Event'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this link with others:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareLink));
                      Get.snackbar(
                        'Copied!',
                        'Link copied',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Join Code: ${event.joinCode}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.pop(context);
              Get.snackbar(
                'Copied!',
                'Invite message copied',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.content_copy),
            label: const Text('Copy Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog(EventModel event) {
    if (widget.onContributeTap != null) {
      widget.onContributeTap!();
    }
  }

  void _copyJoinCode(EventModel event) {
    Clipboard.setData(ClipboardData(text: event.joinCode));
    Get.snackbar(
      'Copied!',
      'Join code copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getParticipantStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'DECLINED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
