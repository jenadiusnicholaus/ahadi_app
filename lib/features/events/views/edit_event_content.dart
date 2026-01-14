import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../models/event_type_model.dart';

/// Edit Event content - renders inside DashboardShell (responsive)
class EditEventContent extends StatefulWidget {
  final EventModel event;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const EditEventContent({
    super.key,
    required this.event,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<EditEventContent> createState() => _EditEventContentState();
}

class _EditEventContentState extends State<EditEventContent> {
  final EventsController controller = Get.find<EventsController>();
  final _formKey = GlobalKey<FormState>();

  // Form data
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _venueController;
  late TextEditingController _targetController;

  EventTypeModel? _selectedEventType;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  late String _visibility;
  late String _status;

  final _isUpdating = false.obs;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final event = widget.event;
    
    _titleController = TextEditingController(text: event.title);
    _descriptionController = TextEditingController(text: event.description);
    _locationController = TextEditingController(text: event.location);
    _venueController = TextEditingController(text: event.venueName);
    _targetController = TextEditingController(
      text: event.contributionTarget?.toStringAsFixed(0) ?? '',
    );

    // Find event type
    if (event.eventType != null) {
      _selectedEventType = controller.eventTypes.firstWhereOrNull(
        (t) => t.id == event.eventType!.id,
      );
    }

    // Parse dates
    _startDate = event.startDate;
    _endDate = event.endDate;
    
    if (event.startDate != null) {
      _startTime = TimeOfDay.fromDateTime(event.startDate!);
    }
    if (event.endDate != null) {
      _endTime = TimeOfDay.fromDateTime(event.endDate!);
    }

    _visibility = event.visibility;
    _status = event.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _venueController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= 900;

    return Form(
      key: _formKey,
      child: isWideScreen ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  // ============ WIDE SCREEN LAYOUT ============
  Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Event',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Update your event details',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => ElevatedButton.icon(
                        onPressed: _isUpdating.value ? null : _updateEvent,
                        icon: _isUpdating.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: Text(_isUpdating.value ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Two column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Main form
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildCard(
                      'Basic Information',
                      'Event name and description',
                      Icons.info_outline,
                      _buildBasicInfoForm(),
                    ),
                    const SizedBox(height: 24),
                    _buildCard(
                      'Date & Location',
                      'When and where is your event?',
                      Icons.calendar_today,
                      _buildDateLocationForm(),
                    ),
                    const SizedBox(height: 24),
                    _buildCard(
                      'Contribution Goal',
                      'Target amount for contributions',
                      Icons.attach_money,
                      _buildContributionForm(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // Right column - Settings
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildCard(
                      'Event Settings',
                      'Visibility and status',
                      Icons.settings,
                      _buildSettingsForm(),
                    ),
                    const SizedBox(height: 24),
                    _buildCard(
                      'Event Status',
                      'Control event lifecycle',
                      Icons.flag,
                      _buildStatusForm(),
                    ),
                    const SizedBox(height: 24),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ MOBILE LAYOUT ============
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Event',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update your event details',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _buildBasicInfoForm(),
                const SizedBox(height: 24),
                _buildDateLocationForm(),
                const SizedBox(height: 24),
                _buildContributionForm(),
                const SizedBox(height: 24),
                _buildSettingsForm(),
                const SizedBox(height: 24),
                _buildStatusForm(),
                const SizedBox(height: 24),
                _buildDangerZone(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildMobileActions(),
      ],
    );
  }

  Widget _buildMobileActions() {
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
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => ElevatedButton(
                onPressed: _isUpdating.value ? null : _updateEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isUpdating.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ SHARED FORM BUILDERS ============

  Widget _buildCard(String title, String subtitle, IconData icon, Widget content) {
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                onSelected: (_) => setState(() => _selectedEventType = type),
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
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildDateLocationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Date & Time
        const Text('Start Date & Time', style: TextStyle(fontWeight: FontWeight.w500)),
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
        const Text('End Date & Time', style: TextStyle(fontWeight: FontWeight.w500)),
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
        TextFormField(
          controller: _targetController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Target Amount (TZS)',
            prefixIcon: const Icon(Icons.attach_money),
            helperText: 'Leave empty for no target',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [500000, 1000000, 2000000, 5000000, 10000000]
              .map((amount) => ActionChip(
                    label: Text(_formatAmount(amount)),
                    onPressed: () => _targetController.text = amount.toString(),
                  ))
              .toList(),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(0)}M';
    }
    return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
  }

  Widget _buildSettingsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Visibility', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        _buildVisibilityOption('PRIVATE', 'Private', 'Only invited', Icons.lock),
        _buildVisibilityOption('INVITE_ONLY', 'Invite Only', 'Anyone with link', Icons.link),
        _buildVisibilityOption('PUBLIC', 'Public', 'Anyone can join', Icons.public),
      ],
    );
  }

  Widget _buildVisibilityOption(String value, String title, String subtitle, IconData icon) {
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
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : Colors.grey),
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
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        _buildStatusOption('DRAFT', 'Draft', Icons.edit_note, Colors.grey),
        _buildStatusOption('ACTIVE', 'Active', Icons.play_circle, Colors.green),
        _buildStatusOption('PAUSED', 'Paused', Icons.pause_circle, Colors.orange),
        _buildStatusOption('COMPLETED', 'Completed', Icons.check_circle, Colors.blue),
        _buildStatusOption('CANCELLED', 'Cancelled', Icons.cancel, Colors.red),
      ],
    );
  }

  Widget _buildStatusOption(String value, String title, IconData icon, Color color) {
    final isSelected = _status == value;

    return InkWell(
      onTap: () => setState(() => _status = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : null,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 1),
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Event'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ACTIONS ============

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
    final initialTime = (isStart ? _startTime : _endTime) ?? TimeOfDay.now();
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
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

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    _isUpdating.value = true;

    try {
      final data = <String, dynamic>{
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'venue_name': _venueController.text,
        'visibility': _visibility,
        'status': _status,
      };

      if (_selectedEventType != null) {
        data['event_type'] = _selectedEventType!.id;
      }

      final startDateTime = _combineDateTime(_startDate, _startTime);
      if (startDateTime != null) {
        data['start_date'] = startDateTime.toIso8601String();
      }

      final endDateTime = _combineDateTime(_endDate, _endTime);
      if (endDateTime != null) {
        data['end_date'] = endDateTime.toIso8601String();
      }

      if (_targetController.text.isNotEmpty) {
        data['contribution_target'] = double.tryParse(_targetController.text);
      }

      final success = await controller.updateEvent(widget.event.id, data);

      if (success) {
        Get.snackbar(
          'Success!',
          'Event updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onSuccess();
      }
    } finally {
      _isUpdating.value = false;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          'Are you sure you want to delete "${widget.event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    _isUpdating.value = true;
    try {
      final success = await controller.deleteEvent(widget.event.id);
      if (success) {
        Get.snackbar(
          'Deleted',
          'Event has been deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onSuccess();
      }
    } finally {
      _isUpdating.value = false;
    }
  }
}
