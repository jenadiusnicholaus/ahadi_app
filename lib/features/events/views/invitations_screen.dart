import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_layout.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/events_controller.dart';
import '../services/event_service.dart';
import '../services/invitation_template_service.dart';
import '../models/invitation_model.dart';
import '../models/invitation_card_template_model.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final EventsController controller = Get.find<EventsController>();
  final EventService _eventService = Get.find<EventService>();
  
  int? eventId;
  String? eventTitle;
  String? eventTypeSlug;
  List<InvitationModel> _invitations = [];
  InvitationCardTemplateModel? _selectedTemplate;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Stats
  int _sentCount = 0;
  int _viewedCount = 0;
  int _respondedCount = 0;
  int _draftCount = 0;

  bool get _isWeddingEvent => eventTypeSlug?.toLowerCase() == 'wedding';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    eventId = args?['eventId'] as int?;
    eventTitle = args?['eventTitle'] as String?;
    eventTypeSlug = args?['eventTypeSlug'] as String?;
    
    if (eventId != null) {
      _loadInvitations();
    }
  }

  Future<void> _loadInvitations() async {
    if (eventId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _invitations = await _eventService.getEventInvitations(eventId!);
      
      // Calculate stats
      _sentCount = _invitations.where((i) => i.status == 'SENT').length;
      _viewedCount = _invitations.where((i) => i.status == 'VIEWED').length;
      _respondedCount = _invitations.where((i) => i.status == 'RESPONDED').length;
      _draftCount = _invitations.where((i) => i.status == 'DRAFT').length;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectTemplate() async {
    final result = await Get.toNamed(
      AppRoutes.invitationTemplates,
      arguments: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'selectionMode': true,
        'selectedTemplateId': _selectedTemplate?.id,
      },
    );

    if (result != null && result is InvitationCardTemplateModel) {
      setState(() => _selectedTemplate = result);
      Get.snackbar(
        'Template Selected',
        'You selected "${result.name}" template',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: 'invitations',
      showBackButton: true,
      onBack: () => Get.back(),
      breadcrumb: DashboardBreadcrumb(
        items: [
          BreadcrumbItem(label: 'Events', onTap: () => Get.back()),
          BreadcrumbItem(label: 'Invitations'),
        ],
      ),
      content: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Invitations',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isWeddingEvent) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: Colors.pink.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Wedding',
                                    style: TextStyle(
                                      color: Colors.pink.shade400,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isWeddingEvent
                            ? 'Create beautiful personalized invitation cards'
                            : 'Send and track event invitations',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isWeddingEvent) ...[
                  OutlinedButton.icon(
                    onPressed: _selectTemplate,
                    icon: const Icon(Icons.style, size: 18),
                    label: Text(
                      _selectedTemplate != null
                          ? _selectedTemplate!.name
                          : 'Choose Template',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton.icon(
                  onPressed: () => _showSendInvitationsDialog(),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send Invitations'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Wedding Template Preview (if selected)
          if (_isWeddingEvent && _selectedTemplate != null)
            _buildTemplatePreviewCard(),

          // Stats Cards
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Sent', '$_sentCount', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Viewed', '$_viewedCount', Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Responded', '$_respondedCount', Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Draft', '$_draftCount', Colors.grey)),
              ],
            ),
          ),

          // Invitations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildInvitationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreviewCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Template Preview
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _parseColor(_selectedTemplate!.primaryColor),
                  _parseColor(_selectedTemplate!.secondaryColor),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.card_giftcard,
                color: _parseColor(_selectedTemplate!.accentColor),
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Template Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _selectedTemplate!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_selectedTemplate!.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedTemplate!.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedTemplate!.categoryDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildColorDot(_selectedTemplate!.primaryColor),
                    const SizedBox(width: 4),
                    _buildColorDot(_selectedTemplate!.secondaryColor),
                    const SizedBox(width: 4),
                    _buildColorDot(_selectedTemplate!.accentColor),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              TextButton.icon(
                onPressed: _selectTemplate,
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _previewTemplate(_selectedTemplate!),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Preview'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(String hexColor) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: _parseColor(hexColor),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _previewTemplate(InvitationCardTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                template.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _parseColor(template.primaryColor),
                      _parseColor(template.secondaryColor),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Wedding Invitation',
                        style: TextStyle(
                          color: _parseColor(template.accentColor),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Groom & Bride',
                        style: TextStyle(
                          color: _parseColor(template.accentColor),
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Guest Name Here',
                        style: TextStyle(
                          color: _parseColor(template.accentColor).withOpacity(0.8),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                template.description,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsList() {
    if (_invitations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          final invitation = _invitations[index];
          return _buildInvitationCard(invitation);
        },
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Failed to load invitations',
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInvitations,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(InvitationModel invitation) {
    final statusColor = _getStatusColor(invitation.status);
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            _getStatusIcon(invitation.status),
            color: statusColor,
          ),
        ),
        title: Text(
          invitation.participantName ?? invitation.participantPhone ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (invitation.participantEmail != null)
              Text(
                invitation.participantEmail!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            if (invitation.participantPhone != null)
              Text(
                invitation.participantPhone!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(invitation.status),
                const SizedBox(width: 12),
                Text(
                  invitation.sentAt != null 
                      ? 'Sent ${dateFormatter.format(invitation.sentAt!)}'
                      : 'Created ${dateFormatter.format(invitation.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'view') {
              _viewInvitationDetails(invitation);
            } else if (value == 'resend') {
              _resendInvitation(invitation);
            } else if (value == 'delete') {
              _deleteInvitation(invitation);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            if (invitation.status != 'RESPONDED')
              const PopupMenuItem(
                value: 'resend',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Resend'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESPONDED':
        return Colors.green;
      case 'VIEWED':
        return Colors.orange;
      case 'SENT':
        return Colors.blue;
      case 'DRAFT':
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'RESPONDED':
        return Icons.check_circle;
      case 'VIEWED':
        return Icons.visibility;
      case 'SENT':
        return Icons.mail;
      case 'DRAFT':
      default:
        return Icons.drafts;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No invitations sent yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Start inviting people to your event',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSendInvitationsDialog(),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Invitations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSendInvitationsDialog() {
    // TODO: Implement send invitations dialog
    Get.snackbar(
      'Coming Soon',
      'Send invitations functionality will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _resendInvitation(InvitationModel invitation) async {
    try {
      await _eventService.sendInvitation(invitation.id);
      Get.snackbar(
        'Success',
        'Invitation resent to ${invitation.participantName ?? invitation.participantPhone}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await _loadInvitations(); // Refresh list
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to resend invitation: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _viewInvitationDetails(InvitationModel invitation) {
    final dateFormatter = DateFormat('MMM d, yyyy HH:mm');
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Invitation Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Name', invitation.participantName ?? '-'),
            _buildDetailRow('Phone', invitation.participantPhone ?? '-'),
            _buildDetailRow('Email', invitation.participantEmail ?? '-'),
            _buildDetailRow('Status', invitation.statusDisplay),
            _buildDetailRow('Created', dateFormatter.format(invitation.createdAt)),
            if (invitation.sentAt != null)
              _buildDetailRow('Sent', dateFormatter.format(invitation.sentAt!)),
            if (invitation.viewedAt != null)
              _buildDetailRow('Viewed', dateFormatter.format(invitation.viewedAt!)),
            if (invitation.respondedAt != null)
              _buildDetailRow('Responded', dateFormatter.format(invitation.respondedAt!)),
            if (invitation.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(invitation.message),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteInvitation(InvitationModel invitation) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Invitation'),
        content: Text(
          'Are you sure you want to delete the invitation for ${invitation.participantName ?? invitation.participantPhone}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _eventService.deleteInvitation(invitation.id);
        Get.snackbar(
          'Success',
          'Invitation deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await _loadInvitations(); // Refresh list
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete invitation: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
