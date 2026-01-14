import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_layout.dart';
import '../controllers/events_controller.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final EventsController controller = Get.find<EventsController>();
  int? eventId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    eventId = args?['eventId'] as int?;
    if (eventId != null) {
      _loadInvitations();
    }
  }

  Future<void> _loadInvitations() async {
    // TODO: Implement load invitations from API
    // For now, using mock data
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
                      const Text(
                        'Invitations',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send and track event invitations',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
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

          // Stats Cards
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Sent', '45', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Viewed', '32', Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Accepted', '28', Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Declined', '3', Colors.red)),
              ],
            ),
          ),

          // Invitations List
          Expanded(
            child: _buildInvitationsList(),
          ),
        ],
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
    // Mock data for demonstration
    final invitations = _getMockInvitations();

    if (invitations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: invitations.length,
      itemBuilder: (context, index) {
        final invitation = invitations[index];
        return _buildInvitationCard(invitation);
      },
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final status = invitation['status'] as String;
    final statusColor = _getStatusColor(status);

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
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(
            _getStatusIcon(status),
            color: statusColor,
          ),
        ),
        title: Text(
          invitation['name'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  invitation['email'] as String,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Sent ${invitation['sentDate']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusChip(status),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'resend') {
              _resendInvitation(invitation);
            } else if (value == 'view') {
              _viewInvitationDetails(invitation);
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'viewed':
        return Colors.orange;
      case 'sent':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'viewed':
        return Icons.visibility;
      case 'sent':
        return Icons.mail;
      default:
        return Icons.email;
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
    Get.snackbar(
      'Coming Soon',
      'Send invitations functionality will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _resendInvitation(Map<String, dynamic> invitation) {
    Get.snackbar(
      'Success',
      'Invitation resent to ${invitation['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _viewInvitationDetails(Map<String, dynamic> invitation) {
    Get.snackbar(
      'Coming Soon',
      'View invitation details will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  List<Map<String, dynamic>> _getMockInvitations() {
    return [
      {
        'name': 'John Doe',
        'email': 'john@example.com',
        'status': 'accepted',
        'sentDate': '2 days ago',
      },
      {
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'status': 'viewed',
        'sentDate': '3 days ago',
      },
      {
        'name': 'Bob Johnson',
        'email': 'bob@example.com',
        'status': 'sent',
        'sentDate': '1 week ago',
      },
      {
        'name': 'Alice Brown',
        'email': 'alice@example.com',
        'status': 'accepted',
        'sentDate': '2 weeks ago',
      },
      {
        'name': 'Charlie Wilson',
        'email': 'charlie@example.com',
        'status': 'declined',
        'sentDate': '1 week ago',
      },
    ];
  }
}
