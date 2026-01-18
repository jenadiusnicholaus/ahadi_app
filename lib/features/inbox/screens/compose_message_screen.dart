import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/inbox_controller.dart';
import '../../events/models/event_model.dart';

/// Screen for composing and sending a direct message
class ComposeMessageScreen extends StatefulWidget {
  final int? recipientId;
  final String? recipientName;
  final EventModel? event;

  const ComposeMessageScreen({
    super.key,
    this.recipientId,
    this.recipientName,
    this.event,
  });

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _recipientController = TextEditingController();
  
  final InboxController _inboxController = Get.find<InboxController>();
  final RxBool _isSending = false.obs;
  
  int? _selectedRecipientId;

  @override
  void initState() {
    super.initState();
    if (widget.recipientId != null) {
      _selectedRecipientId = widget.recipientId;
      _recipientController.text = widget.recipientName ?? 'User ${widget.recipientId}';
    }
    if (widget.event != null) {
      _titleController.text = 'Re: ${widget.event!.title}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipientId == null) {
      Get.snackbar(
        'Error',
        'Please select a recipient',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _isSending.value = true;
    try {
      await _inboxController.sendDirectMessage(
        recipientId: _selectedRecipientId!,
        content: _contentController.text.trim(),
        title: _titleController.text.trim().isNotEmpty 
            ? _titleController.text.trim() 
            : null,
        eventId: widget.event?.id,
      );

      Get.back();
      Get.snackbar(
        'Success',
        'Message sent successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSending.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Obx(() => _isSending.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _sendMessage,
                  child: const Text(
                    'Send',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Recipient field
            TextFormField(
              controller: _recipientController,
              readOnly: widget.recipientId != null,
              decoration: InputDecoration(
                labelText: 'To',
                hintText: 'Select recipient',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: widget.recipientId == null
                    ? IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _showRecipientPicker,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: widget.recipientId == null ? _showRecipientPicker : null,
              validator: (value) {
                if (_selectedRecipientId == null) {
                  return 'Please select a recipient';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Title field (optional)
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Subject (optional)',
                hintText: 'Enter subject',
                prefixIcon: const Icon(Icons.subject),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Event context (if any)
            if (widget.event != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Related Event',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            widget.event!.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.event != null) const SizedBox(height: 16),

            // Message content
            TextFormField(
              controller: _contentController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Write your message here...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipientPicker() {
    // Show a bottom sheet to search/select recipients
    Get.bottomSheet(
      _RecipientPickerSheet(
        onRecipientSelected: (int id, String name) {
          setState(() {
            _selectedRecipientId = id;
            _recipientController.text = name;
          });
          Get.back();
        },
      ),
      isScrollControlled: true,
    );
  }
}

/// Bottom sheet for picking a recipient
class _RecipientPickerSheet extends StatefulWidget {
  final Function(int id, String name) onRecipientSelected;

  const _RecipientPickerSheet({required this.onRecipientSelected});

  @override
  State<_RecipientPickerSheet> createState() => _RecipientPickerSheetState();
}

class _RecipientPickerSheetState extends State<_RecipientPickerSheet> {
  final _searchController = TextEditingController();
  List<_RecipientOption> _recipients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    // Load participants from user's events
    try {
      final eventsController = Get.find<dynamic>();
      // Combine participants from all events
      final allEvents = [
        ...eventsController.myEvents,
        ...eventsController.invitedEvents,
      ];
      
      final Set<int> addedIds = {};
      final List<_RecipientOption> recipients = [];
      
      for (final event in allEvents) {
        // Add event owner
        if (event.owner != null && !addedIds.contains(event.owner.id)) {
          addedIds.add(event.owner.id);
          recipients.add(_RecipientOption(
            id: event.owner.id,
            name: event.owner.fullName ?? 'User ${event.owner.id}',
            subtitle: 'Owner of ${event.title}',
          ));
        }
      }
      
      setState(() {
        _recipients = recipients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Recipient',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recipients.isEmpty
                    ? const Center(
                        child: Text('No recipients found'),
                      )
                    : ListView.builder(
                        itemCount: _filteredRecipients.length,
                        itemBuilder: (context, index) {
                          final recipient = _filteredRecipients[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                recipient.name.isNotEmpty
                                    ? recipient.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            title: Text(recipient.name),
                            subtitle: recipient.subtitle != null
                                ? Text(recipient.subtitle!)
                                : null,
                            onTap: () => widget.onRecipientSelected(
                              recipient.id,
                              recipient.name,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<_RecipientOption> get _filteredRecipients {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _recipients;
    return _recipients
        .where((r) => r.name.toLowerCase().contains(query))
        .toList();
  }
}

class _RecipientOption {
  final int id;
  final String name;
  final String? subtitle;

  _RecipientOption({
    required this.id,
    required this.name,
    this.subtitle,
  });
}
