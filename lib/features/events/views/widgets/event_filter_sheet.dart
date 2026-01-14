import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/event_type_model.dart';

class EventFilterSheet extends StatelessWidget {
  final List<EventTypeModel> eventTypes;
  final int? selectedTypeId;
  final String? selectedStatus;
  final Function(int?) onTypeSelected;
  final Function(String?) onStatusSelected;
  final VoidCallback onClear;

  const EventFilterSheet({
    super.key,
    required this.eventTypes,
    this.selectedTypeId,
    this.selectedStatus,
    required this.onTypeSelected,
    required this.onStatusSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Events', style: AppTextStyles.h3),
              TextButton(
                onPressed: () {
                  onClear();
                  Get.back();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Event Type Filter
          Text(
            'Event Type',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip(null, 'All Types'),
              ...eventTypes.map((type) => _buildTypeChip(type.id, type.name)),
            ],
          ),
          const SizedBox(height: 24),

          // Status Filter
          Text(
            'Status',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(null, 'All'),
              _buildStatusChip('DRAFT', 'Draft'),
              _buildStatusChip('ACTIVE', 'Active'),
              _buildStatusChip('COMPLETED', 'Completed'),
              _buildStatusChip('CANCELLED', 'Cancelled'),
            ],
          ),
          const SizedBox(height: 32),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(int? typeId, String label) {
    final isSelected = selectedTypeId == typeId;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTypeSelected(typeId),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatusChip(String? status, String label) {
    final isSelected = selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onStatusSelected(status),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }
}
