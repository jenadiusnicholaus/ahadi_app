import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/events_controller.dart';
import '../models/event_type_model.dart';
import '../models/invitation_card_template_model.dart';
import 'invitation_templates_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final EventsController controller = Get.find<EventsController>();
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

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
  bool _chatEnabled = true;

  // Wedding-specific fields
  InvitationCardTemplateModel? _selectedTemplate;
  TimeOfDay? _ceremonyTime;
  TimeOfDay? _receptionTime;

  /// Check if the selected event type is a wedding
  bool get _isWedding {
    final slug = _selectedEventType?.slug.toLowerCase();
    debugPrint(
      '🔍 Selected event type: ${_selectedEventType?.name}, slug: $slug',
    );
    return slug == 'wedding';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _venueController.dispose();
    _targetController.dispose();
    _groomNameController.dispose();
    _brideNameController.dispose();
    _receptionVenueController.dispose();
    _dressCodeController.dispose();
    _rsvpPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        actions: [
          TextButton(onPressed: _saveDraft, child: const Text('Save Draft')),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Page view
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildBasicInfoStep(),
                  _buildDateLocationStep(),
                  _buildContributionStep(),
                  _buildSettingsStep(),
                ],
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(),
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

  // Step 1: Basic Info
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Tell us about your event',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Event Type
          Text(
            'Event Type',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
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
                    debugPrint(
                      '📌 Selected event type: ${type.name}, slug: ${type.slug}',
                    );
                    setState(() => _selectedEventType = type);
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Event Title *',
              hintText: 'e.g., John & Jane Wedding Celebration',
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
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Tell guests about your event...',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),

          // Wedding-specific fields
          if (_isWedding) ...[
            const SizedBox(height: 32),
            _buildWeddingDetailsSection(),
          ],
        ],
      ),
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
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add wedding-specific information for personalized invitations',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.pink[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Invitation Card Template Selection
        Text(
          'Invitation Card Template',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a beautiful template for your wedding invitations',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
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
                decoration: const InputDecoration(
                  labelText: 'Groom\'s Name',
                  hintText: 'e.g., John',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _brideNameController,
                decoration: const InputDecoration(
                  labelText: 'Bride\'s Name',
                  hintText: 'e.g., Jane',
                  prefixIcon: Icon(Icons.person),
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
      final isCanvas = _selectedTemplate!.isCanvasTemplate;
      
      // Show selected template preview
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Template Preview - use styled preview for canvas, image for others
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: isCanvas 
                  ? _buildCanvasPreview()
                  : (_selectedTemplate!.previewImage != null
                      ? Image.network(
                          _selectedTemplate!.previewImage!,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackPreview(120),
                        )
                      : _buildFallbackPreview(120)),
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
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedTemplate!.categoryDisplay,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
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

  /// Build canvas template preview with actual styling
  Widget _buildCanvasPreview() {
    final template = _selectedTemplate!;
    final primaryColor = _parseColor(template.primaryColor);
    final secondaryColor = _parseColor(template.secondaryColor);
    final accentColor = _parseColor(template.accentColor);
    final style = template.canvasStyle ?? 'elegant';
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor, accentColor.withValues(alpha: 0.95)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements based on style
          if (style == 'floral') ...[
            Positioned(top: 10, left: 10, child: Text('🌸', style: TextStyle(fontSize: 20))),
            Positioned(top: 10, right: 10, child: Text('🌺', style: TextStyle(fontSize: 20))),
            Positioned(bottom: 10, left: 10, child: Text('🌷', style: TextStyle(fontSize: 20))),
            Positioned(bottom: 10, right: 10, child: Text('🌹', style: TextStyle(fontSize: 20))),
          ],
          
          // Border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 0.5),
              ),
            ),
          ),
          
          // Content
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
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bride & Groom',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 40, height: 1, color: primaryColor),
                const SizedBox(height: 8),
                Text(
                  'Your Wedding Date',
                  style: TextStyle(
                    color: secondaryColor.withValues(alpha: 0.7),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Canvas badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Canvas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parse hex color string to Color
  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Build fallback preview when image fails to load
  Widget _buildFallbackPreview(double height) {
    return Container(
      height: height,
      color: Color(
        int.parse(
          _selectedTemplate!.primaryColor.replaceFirst('#', '0xFF'),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.card_giftcard,
          size: 40,
          color: Colors.white,
        ),
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

  // Step 2: Date & Location
  Widget _buildDateLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Location', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'When and where is your event?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Start Date
          Text(
            'Start Date & Time',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: _startDate != null
                      ? DateFormat('MMM d, yyyy').format(_startDate!)
                      : 'Select Date',
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePicker(
                  label: _startTime != null
                      ? _startTime!.format(context)
                      : 'Select Time',
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // End Date
          Text(
            'End Date & Time (Optional)',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: _endDate != null
                      ? DateFormat('MMM d, yyyy').format(_endDate!)
                      : 'Select Date',
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePicker(
                  label: _endTime != null
                      ? _endTime!.format(context)
                      : 'Select Time',
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Location
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'Address or area',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),

          // Venue
          TextFormField(
            controller: _venueController,
            decoration: const InputDecoration(
              labelText: 'Venue Name',
              hintText: 'e.g., Grand Hotel Ballroom',
              prefixIcon: Icon(Icons.place),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.access_time,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

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

  // Step 3: Contribution Target
  Widget _buildContributionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contribution Goal', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Set a target for contributions (optional)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Target amount
          TextFormField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target Amount (TZS)',
              hintText: 'e.g., 5000000',
              prefixIcon: Icon(Icons.attach_money),
              helperText: 'Leave empty if you don\'t want to set a target',
            ),
          ),
          const SizedBox(height: 24),

          // Quick amounts
          Text(
            'Quick Select',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAmountChip(500000),
              _buildAmountChip(1000000),
              _buildAmountChip(2000000),
              _buildAmountChip(5000000),
              _buildAmountChip(10000000),
            ],
          ),
          const SizedBox(height: 32),

          // Auto disbursement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.autorenew, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Auto Disbursement',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _autoDisburse,
                      onChanged: (value) =>
                          setState(() => _autoDisburse = value),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Automatically transfer contributions to your mobile money account',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  // Step 4: Settings
  Widget _buildSettingsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Settings', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Configure how your event works',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Chat Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Event Chat',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Allow participants to chat in real-time',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _chatEnabled,
                  onChanged: (value) {
                    setState(() => _chatEnabled = value);
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Visibility
          Text(
            'Visibility',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildVisibilityOption(
            'PRIVATE',
            'Private',
            'Only invited participants can see and join',
            Icons.lock,
          ),
          _buildVisibilityOption(
            'INVITE_ONLY',
            'Invite Only',
            'Anyone with the link can view, but must be invited to join',
            Icons.link,
          ),
          _buildVisibilityOption(
            'PUBLIC',
            'Public',
            'Anyone can find and join your event',
            Icons.public,
          ),
          const SizedBox(height: 24),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  'Event',
                  _titleController.text.isEmpty
                      ? 'Not set'
                      : _titleController.text,
                ),
                _buildSummaryItem(
                  'Type',
                  _selectedEventType?.name ?? 'Not selected',
                ),
                _buildSummaryItem(
                  'Date',
                  _startDate != null
                      ? DateFormat('MMM d, yyyy').format(_startDate!)
                      : 'Not set',
                ),
                _buildSummaryItem(
                  'Location',
                  _locationController.text.isEmpty
                      ? 'Not set'
                      : _locationController.text,
                ),
                _buildSummaryItem(
                  'Target',
                  _targetController.text.isEmpty
                      ? 'No target'
                      : 'TZS ${_targetController.text}',
                ),
                _buildSummaryItem(
                  'Visibility',
                  _visibility == 'PRIVATE'
                      ? 'Private'
                      : _visibility == 'PUBLIC'
                      ? 'Public'
                      : 'Invite Only',
                ),
                // Wedding-specific summary items
                if (_isWedding) ...[
                  const Divider(height: 24),
                  Text(
                    'Wedding Details',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    'Template',
                    _selectedTemplate?.name ?? 'Not selected',
                  ),
                  if (_groomNameController.text.isNotEmpty ||
                      _brideNameController.text.isNotEmpty)
                    _buildSummaryItem(
                      'Couple',
                      '${_groomNameController.text} & ${_brideNameController.text}',
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isCreating.value ? null : _nextStep,
                child: controller.isCreating.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
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

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate basic info
      if (_titleController.text.isEmpty) {
        Get.snackbar('Error', 'Please enter event title');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createEvent();
    }
  }

  void _saveDraft() {
    _createEvent(asDraft: true);
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _createEvent({bool asDraft = false}) async {
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
      chatEnabled: _chatEnabled,
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
      Get.back();
      Get.snackbar(
        'Success!',
        asDraft ? 'Event saved as draft' : 'Event created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}
