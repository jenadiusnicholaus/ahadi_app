import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/events_controller.dart';
import '../models/event_type_model.dart';
import '../models/invitation_card_template_model.dart';
import '../services/event_draft_service.dart';
import 'invitation_templates_screen.dart';

/// Create Event content - renders inside DashboardShell (responsive)
class CreateEventContent extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const CreateEventContent({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<CreateEventContent> createState() => _CreateEventContentState();
}

class _CreateEventContentState extends State<CreateEventContent> {
  final EventsController controller = Get.find<EventsController>();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final EventDraftService _draftService;

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form data
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _venueController = TextEditingController();
  final _targetController = TextEditingController();

  // Wedding-specific controllers
  final _groomNameController = TextEditingController();
  final _brideNameController = TextEditingController();
  final _receptionVenueController = TextEditingController();
  final _dressCodeController = TextEditingController();
  final _rsvpPhoneController = TextEditingController();

  EventTypeModel? _selectedEventType;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _visibility = 'PRIVATE';
  bool _autoDisburse = true;

  // Wedding-specific fields
  InvitationCardTemplateModel? _selectedTemplate;
  TimeOfDay? _ceremonyTime;
  TimeOfDay? _receptionTime;

  /// Check if the selected event type is a wedding
  bool get _isWedding {
    final slug = _selectedEventType?.slug;
    return slug != null && slug.toLowerCase() == 'wedding';
  }

  // Cover image
  Uint8List? _coverImageBytes;
  String? _coverImageName;

  @override
  void initState() {
    super.initState();
    _initDraftService();
  }

  void _initDraftService() {
    // Register draft service if not already registered
    if (!Get.isRegistered<EventDraftService>()) {
      Get.put(EventDraftService());
    }
    _draftService = Get.find<EventDraftService>();

    // Check for existing draft
    _checkForDraft();
  }

  void _checkForDraft() {
    final draft = _draftService.loadDraft();
    if (draft != null && !draft.isEmpty) {
      // Show dialog to restore draft
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRestoreDraftDialog(draft);
      });
    }
  }

  void _showRestoreDraftDialog(EventDraft draft) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('Restore Draft?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have an unsaved event draft:'),
            const SizedBox(height: 12),
            if (draft.title != null)
              Text(
                'Title: ${draft.title}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            Text(
              'Saved: ${_formatDraftDate(draft.savedAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _draftService.clearDraft();
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _restoreDraft(draft);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  String _formatDraftDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _restoreDraft(EventDraft draft) {
    setState(() {
      if (draft.title != null) _titleController.text = draft.title!;
      if (draft.description != null) {
        _descriptionController.text = draft.description!;
      }
      if (draft.location != null) _locationController.text = draft.location!;
      if (draft.venue != null) _venueController.text = draft.venue!;
      if (draft.targetAmount != null) {
        _targetController.text = draft.targetAmount!.toString();
      }
      if (draft.visibility != null) _visibility = draft.visibility!;
      if (draft.autoDisburse != null) _autoDisburse = draft.autoDisburse!;

      // Restore event type
      if (draft.eventTypeId != null) {
        _selectedEventType = controller.eventTypes.firstWhereOrNull(
          (t) => t.id == draft.eventTypeId,
        );
      }

      // Restore dates
      if (draft.startDate != null) {
        _startDate = DateTime.tryParse(draft.startDate!);
      }
      if (draft.startTime != null) {
        final parts = draft.startTime!.split(':');
        if (parts.length >= 2) {
          _startTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      if (draft.endDate != null) {
        _endDate = DateTime.tryParse(draft.endDate!);
      }
      if (draft.endTime != null) {
        final parts = draft.endTime!.split(':');
        if (parts.length >= 2) {
          _endTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }

      // Restore cover image
      if (draft.coverImageBase64 != null) {
        _coverImageBytes = base64Decode(draft.coverImageBase64!);
        _coverImageName = draft.coverImageName;
      }
    });

    Get.snackbar(
      'Draft Restored',
      'Your previous draft has been restored',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _saveDraft() {
    final draft = EventDraft(
      title: _titleController.text.isNotEmpty ? _titleController.text : null,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      eventTypeId: _selectedEventType?.id,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      venue: _venueController.text.isNotEmpty ? _venueController.text : null,
      startDate: _startDate?.toIso8601String(),
      startTime: _startTime != null
          ? '${_startTime!.hour}:${_startTime!.minute}'
          : null,
      endDate: _endDate?.toIso8601String(),
      endTime: _endTime != null
          ? '${_endTime!.hour}:${_endTime!.minute}'
          : null,
      targetAmount: double.tryParse(_targetController.text),
      visibility: _visibility,
      autoDisburse: _autoDisburse,
      coverImageBase64: _coverImageBytes != null
          ? base64Encode(_coverImageBytes!)
          : null,
      coverImageName: _coverImageName,
    );

    if (!draft.isEmpty) {
      _draftService.saveDraft(draft);
    }
  }

  @override
  void dispose() {
    // Auto-save draft on dispose if there's data
    _saveDraft();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _venueController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey, child: _buildMobileLayout());
  }

  // ============ MOBILE LAYOUT (Stepper) ============
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),

        // Step content
        Expanded(
          child: IndexedStack(
            index: _currentStep,
            children: [
              _buildMobileStep(
                'Basic Information',
                'Tell us about your event',
                _buildBasicInfoForm(),
              ),
              _buildMobileStep(
                'Date & Location',
                'When and where is your event?',
                _buildDateLocationForm(),
              ),
              _buildMobileStep(
                'Contribution Goal',
                'Set a target (optional)',
                _buildContributionForm(),
              ),
              _buildMobileStep(
                'Settings',
                'Configure your event',
                Column(
                  children: [
                    _buildSettingsForm(),
                    const SizedBox(height: 24),
                    _buildMobilePreview(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Navigation buttons
        _buildMobileNavigationButtons(),
      ],
    );
  }

  Widget _buildMobileStep(String title, String subtitle, Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.primary : Colors.grey[300],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppColors.primary : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isCreating.value ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: controller.isCreating.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == _totalSteps - 1
                            ? 'Create Event'
                            : 'Next',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ SHARED FORM BUILDERS ============

  Widget _buildCard(
    String title,
    String subtitle,
    IconData icon,
    Widget content,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Image
        const Text(
          'Cover Image',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildImagePicker(),
        const SizedBox(height: 20),

        // Event Type
        const Text('Event Type', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.eventTypes.map((type) {
              final isSelected = _selectedEventType?.id == type.id;
              return ChoiceChip(
                label: Text(type.name),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedEventType = type);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Event Title *',
            hintText: 'e.g., John & Jane Wedding Celebration',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter event title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Tell guests about your event...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 4,
        ),

        // Wedding-specific fields
        if (_isWedding) ...[
          const SizedBox(height: 32),
          _buildWeddingDetailsSection(),
        ],
      ],
    );
  }

  /// Build the wedding details section
  Widget _buildWeddingDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pink[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Colors.pink[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wedding Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add wedding-specific information for personalized invitations',
                      style: TextStyle(fontSize: 12, color: Colors.pink[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Invitation Card Template Selection
        const Text(
          'Invitation Card Template',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a beautiful template for your wedding invitations',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        // Template Selection Button/Preview
        _buildTemplateSelector(),
        const SizedBox(height: 24),

        // Bride & Groom Names
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _groomNameController,
                decoration: InputDecoration(
                  labelText: 'Groom\'s Name',
                  hintText: 'e.g., John',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _brideNameController,
                decoration: InputDecoration(
                  labelText: 'Bride\'s Name',
                  hintText: 'e.g., Jane',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build the template selector widget
  Widget _buildTemplateSelector() {
    if (_selectedTemplate != null) {
      // Show selected template preview
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Template Preview
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: _selectedTemplate!.previewImage != null
                  ? Image.network(
                      _selectedTemplate!.previewImage!,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Color(
                          int.parse(
                            _selectedTemplate!.primaryColor.replaceFirst(
                              '#',
                              '0xFF',
                            ),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 120,
                      color: Color(
                        int.parse(
                          _selectedTemplate!.primaryColor.replaceFirst(
                            '#',
                            '0xFF',
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.card_giftcard,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
                          _selectedTemplate!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedTemplate!.categoryDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _selectTemplate,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show selection button
    return OutlinedButton.icon(
      onPressed: _selectTemplate,
      icon: const Icon(Icons.card_giftcard),
      label: const Text('Choose Invitation Template'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: BorderSide(color: Colors.pink[300]!),
        foregroundColor: Colors.pink[700],
      ),
    );
  }

  /// Navigate to template selection screen
  Future<void> _selectTemplate() async {
    final result = await Get.to<InvitationCardTemplateModel>(
      () => const InvitationTemplatesScreen(),
      arguments: {
        'selectionMode': true,
        'selectedTemplateId': _selectedTemplate?.id,
      },
    );

    if (result != null) {
      setState(() {
        _selectedTemplate = result;
      });
    }
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: _coverImageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_coverImageBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => setState(() {
                        _coverImageBytes = null;
                        _coverImageName = null;
                      }),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Cover Image',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Click to upload',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _coverImageBytes = bytes;
          _coverImageName = image.name;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildDateLocationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Date & Time
        const Text(
          'Start Date & Time',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDatePicker(true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker(true)),
          ],
        ),
        const SizedBox(height: 16),

        // End Date & Time
        const Text(
          'End Date & Time (Optional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDatePicker(false)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker(false)),
          ],
        ),
        const SizedBox(height: 20),

        // Location
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Address or area',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Venue
        TextFormField(
          controller: _venueController,
          decoration: InputDecoration(
            labelText: 'Venue Name',
            hintText: 'e.g., Grand Hotel Ballroom',
            prefixIcon: const Icon(Icons.place),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return InkWell(
      onTap: () => _pickDate(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? DateFormat('MMM d, yyyy').format(date)
                  : 'Select Date',
              style: TextStyle(
                color: date != null ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(bool isStart) {
    final time = isStart ? _startTime : _endTime;
    return InkWell(
      onTap: () => _pickTime(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: 8),
            Text(
              time != null ? time.format(context) : 'Select Time',
              style: TextStyle(
                color: time != null ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target amount
        TextFormField(
          controller: _targetController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Target Amount (TZS)',
            hintText: 'e.g., 5000000',
            prefixIcon: const Icon(Icons.attach_money),
            helperText: 'Leave empty if you don\'t want to set a target',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Quick amounts
        const Text(
          'Quick Select',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            500000,
            1000000,
            2000000,
            5000000,
            10000000,
          ].map((amount) => _buildAmountChip(amount)).toList(),
        ),
        const SizedBox(height: 24),

        // Auto disbursement
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.autorenew, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto Disbursement',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Automatically transfer to your mobile money',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoDisburse,
                onChanged: (value) => setState(() => _autoDisburse = value),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountChip(int amount) {
    final formatted = amount >= 1000000
        ? '${(amount / 1000000).toStringAsFixed(0)}M'
        : '${(amount / 1000).toStringAsFixed(0)}K';

    return ActionChip(
      label: Text('TZS $formatted'),
      onPressed: () {
        _targetController.text = amount.toString();
      },
    );
  }

  Widget _buildSettingsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Visibility', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        _buildVisibilityOption(
          'PRIVATE',
          'Private',
          'Only invited participants',
          Icons.lock,
        ),
        _buildVisibilityOption(
          'INVITE_ONLY',
          'Invite Only',
          'Anyone with link can view',
          Icons.link,
        ),
        _buildVisibilityOption(
          'PUBLIC',
          'Public',
          'Anyone can find and join',
          Icons.public,
        ),
      ],
    );
  }

  Widget _buildVisibilityOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _visibility == value;

    return InkWell(
      onTap: () => setState(() => _visibility = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.preview,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildPreviewContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPreviewContent(),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Column(
      children: [
        _buildPreviewItem(
          'Event',
          _titleController.text.isEmpty ? 'Not set' : _titleController.text,
        ),
        _buildPreviewItem('Type', _selectedEventType?.name ?? 'Not selected'),
        _buildPreviewItem(
          'Date',
          _startDate != null
              ? DateFormat('MMM d, yyyy').format(_startDate!)
              : 'Not set',
        ),
        _buildPreviewItem(
          'Location',
          _locationController.text.isEmpty
              ? 'Not set'
              : _locationController.text,
        ),
        _buildPreviewItem(
          'Target',
          _targetController.text.isEmpty
              ? 'No target'
              : 'TZS ${_targetController.text}',
        ),
        _buildPreviewItem(
          'Visibility',
          _visibility == 'PRIVATE'
              ? 'Private'
              : _visibility == 'PUBLIC'
              ? 'Public'
              : 'Invite Only',
        ),
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ============ ACTIONS ============

  Future<void> _pickDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_titleController.text.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter event title',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _createEvent();
    }
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _createEvent({bool asDraft = false}) async {
    if (_titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter event title',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Convert image to base64 if present
    String? coverImageBase64;
    if (_coverImageBytes != null) {
      final base64Image = base64Encode(_coverImageBytes!);
      // Get file extension from name or default to jpg
      final ext = _coverImageName?.split('.').last.toLowerCase() ?? 'jpg';
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      coverImageBase64 = 'data:$mimeType;base64,$base64Image';
    }

    // Format time to HH:mm string for backend
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    final event = await controller.createEvent(
      title: _titleController.text,
      description: _descriptionController.text,
      eventTypeId: _selectedEventType?.id,
      startDate: _combineDateTime(_startDate, _startTime),
      endDate: _combineDateTime(_endDate, _endTime),
      location: _locationController.text,
      venueName: _venueController.text,
      contributionTarget: double.tryParse(_targetController.text),
      visibility: _visibility,
      status: asDraft ? 'DRAFT' : 'ACTIVE',
      coverImageBase64: coverImageBase64,
      // Wedding-specific fields
      invitationCardTemplateId: _isWedding ? _selectedTemplate?.id : null,
      weddingGroomName: _isWedding ? _groomNameController.text : null,
      weddingBrideName: _isWedding ? _brideNameController.text : null,
      weddingCeremonyTime: _isWedding ? formatTime(_ceremonyTime) : null,
      weddingReceptionTime: _isWedding ? formatTime(_receptionTime) : null,
      weddingReceptionVenue: _isWedding ? _receptionVenueController.text : null,
      weddingDressCode: _isWedding ? _dressCodeController.text : null,
      weddingRsvpPhone: _isWedding ? _rsvpPhoneController.text : null,
    );

    if (event != null) {
      // Clear draft on successful creation
      _draftService.clearDraft();

      Get.snackbar(
        'Success!',
        asDraft ? 'Event saved as draft' : 'Event created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      widget.onSuccess();
    }
  }
}
