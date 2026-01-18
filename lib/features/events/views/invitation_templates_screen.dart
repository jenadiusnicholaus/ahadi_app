import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_layout.dart';
import '../models/invitation_card_template_model.dart';
import '../services/invitation_template_service.dart';

/// Screen for selecting wedding invitation card templates
class InvitationTemplatesScreen extends StatefulWidget {
  const InvitationTemplatesScreen({super.key});

  @override
  State<InvitationTemplatesScreen> createState() =>
      _InvitationTemplatesScreenState();
}

class _InvitationTemplatesScreenState extends State<InvitationTemplatesScreen> {
  final InvitationTemplateService _templateService =
      Get.find<InvitationTemplateService>();

  List<InvitationCardTemplateModel> _templates = [];
  List<TemplateCategoryModel> _categories = [];
  String? _selectedCategory;
  int? _selectedTemplateId;
  InvitationCardTemplateModel? _selectedTemplateObject; // Store full object to prevent mismatch
  bool _isLoading = false;
  String? _errorMessage;

  // Event context - used when generating cards for a specific event
  // ignore: unused_field
  int? _eventId;
  String? _eventTitle;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _eventId = args?['eventId'] as int?;
    _eventTitle = args?['eventTitle'] as String?;
    _isSelectionMode = args?['selectionMode'] as bool? ?? false;
    _selectedTemplateId = args?['selectedTemplateId'] as int?;

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load categories and templates in parallel
      final results = await Future.wait([
        _templateService.getCategories(),
        _templateService.getTemplates(category: _selectedCategory),
      ]);

      setState(() {
        _categories = results[0] as List<TemplateCategoryModel>;
        _templates = results[1] as List<InvitationCardTemplateModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _filterByCategory(String? category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      _templates = await _templateService.getTemplates(category: category);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _selectTemplate(InvitationCardTemplateModel template) {
    setState(() {
      _selectedTemplateId = template.id;
      _selectedTemplateObject = template; // Store the actual template object
    });
    // Preview shows at top automatically - no modal needed
  }

  void _confirmSelection() {
    if (_selectedTemplateObject != null) {
      // Return the stored template object directly to avoid mismatch
      Get.back(result: _selectedTemplateObject);
    } else if (_selectedTemplateId != null) {
      // Fallback: try to find in current list
      final selectedTemplate = _templates.firstWhereOrNull(
        (t) => t.id == _selectedTemplateId,
      );
      if (selectedTemplate != null) {
        Get.back(result: selectedTemplate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: 'invitation-templates',
      showBackButton: true,
      onBack: () => Get.back(),
      breadcrumb: DashboardBreadcrumb(
        items: [
          if (_eventTitle != null)
            BreadcrumbItem(label: _eventTitle!, onTap: () => Get.back()),
          BreadcrumbItem(label: 'Invitation Templates'),
        ],
      ),
      content: Column(
        children: [
          // Header with category filters
          _buildHeader(),

          // Content - full preview area
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitation Template',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Select a beautiful template for your wedding invitations',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSelectionMode && _selectedTemplateId != null)
                ElevatedButton.icon(
                  onPressed: _confirmSelection,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Use Selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(null, 'All'),
                ..._categories.map(
                  (cat) => _buildCategoryChip(cat.code, cat.name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? code, String name) {
    final isSelected = _selectedCategory == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (_) => _filterByCategory(code),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading templates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Get selected template for preview - use stored object first, fallback to list search
    final selectedTemplate = _selectedTemplateObject ?? _templates.firstWhereOrNull(
      (t) => t.id == _selectedTemplateId,
    );

    return Column(
      children: [
        // Large Preview Card - Full clean preview
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildLargePreviewCard(selectedTemplate),
          ),
        ),

        // Horizontal Template Selection - compact
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              return _buildHorizontalTemplateCard(template);
            },
          ),
        ),
      ],
    );
  }

  /// Clean template info bar below preview
  Widget _buildLargePreviewCard(InvitationCardTemplateModel? template) {
    if (template == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 15),
                  ],
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 40,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a Template',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap on any card below',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final primaryColor = _parseColor(template.primaryColor);
    final secondaryColor = _parseColor(template.secondaryColor);
    final accentColor = _parseColor(template.accentColor);

    // Clean preview card - NO overlays blocking the design
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildLargeStyledPreview(
          template,
          primaryColor,
          secondaryColor,
          accentColor,
        ),
      ),
    );
  }

  /// Build large styled preview based on template design
  Widget _buildLargeStyledPreview(
    InvitationCardTemplateModel template,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    // For Canvas templates, show dynamic preview from server
    if (template.isCanvasTemplate) {
      return _buildCanvasTemplatePreview(template, primaryColor, secondaryColor, accentColor);
    }
    
    switch (template.slug) {
      case 'rose-floral-elegance':
      case 'romantic-roses':
        return _buildLargeRosePreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'art-deco-navy':
        return _buildLargeArtDecoPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'celestial-night':
        return _buildLargeCelestialPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'modern-gold':
        return _buildLargeModernGoldPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'greenery-minimal':
        return _buildLargeGreeneryPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'african-heritage':
      case 'swahili-elegance':
        return _buildLargeAfricanPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'colorful-floral':
        return _buildLargeColorfulFloralPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'watercolor-garden':
        return _buildLargeWatercolorPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'rustic-bohemian':
        return _buildLargeRusticPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'tropical-paradise':
        return _buildLargeTropicalPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'winter-wonderland':
        return _buildLargeWinterPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'royal-luxury':
        return _buildLargeRoyalPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'vintage-lace':
        return _buildLargeVintageLacePreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      default:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [secondaryColor, secondaryColor.withOpacity(0.8)],
            ),
          ),
          child: _buildLargePreviewContent(template),
        );
    }
  }

  /// Build Canvas/ReportLab template preview
  Widget _buildCanvasTemplatePreview(
    InvitationCardTemplateModel template,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    // Get the preview URL from the API
    final baseUrl = _templateService.getBaseUrl();
    final previewUrl = '$baseUrl/api/v1/invitation-templates/${template.id}/preview/?format=png';
    
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentColor,
                accentColor.withOpacity(0.95),
              ],
            ),
          ),
        ),
        
        // Canvas preview image from server
        Center(
          child: Image.network(
            previewUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Canvas Preview...',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Fallback to styled preview if image loading fails
              return _buildCanvasFallbackPreview(
                template,
                primaryColor,
                secondaryColor,
                accentColor,
              );
            },
          ),
        ),
        
        // Canvas badge at top
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade600,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Canvas Design',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Template info at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  secondaryColor.withOpacity(0.9),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Professional Canva-style template • ${template.canvasStyle ?? "elegant"} design',
                  style: TextStyle(
                    color: accentColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback preview when Canvas image loading fails
  Widget _buildCanvasFallbackPreview(
    InvitationCardTemplateModel template,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    final style = template.canvasStyle ?? 'elegant';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor, accentColor.withOpacity(0.9)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements based on style
          if (style == 'floral') ...[
            Positioned(top: 20, left: 20, child: Text('🌸', style: TextStyle(fontSize: 32))),
            Positioned(top: 20, right: 20, child: Text('🌺', style: TextStyle(fontSize: 32))),
            Positioned(bottom: 80, left: 20, child: Text('🌷', style: TextStyle(fontSize: 32))),
            Positioned(bottom: 80, right: 20, child: Text('🌹', style: TextStyle(fontSize: 32))),
          ],
          if (style == 'geometric') ...[
            Positioned.fill(
              child: CustomPaint(
                painter: _GeometricPatternPainter(primaryColor.withOpacity(0.2)),
              ),
            ),
          ],
          
          // Border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 2),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withOpacity(0.5), width: 1),
              ),
            ),
          ),
          
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WEDDING INVITATION',
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.6),
                      fontSize: 12,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sarah',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    '&',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    'James',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 60,
                    height: 2,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'January 25, 2026',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 16,
                      letterSpacing: 2,
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

  Widget _buildLargeRosePreview(Color primary, Color secondary, Color accent) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2d1515), Color(0xFF1a0a0a)],
        ),
      ),
      child: Stack(
        children: [
          // Rose corners
          const Positioned(
            top: 15,
            left: 15,
            child: Text('🌹', style: TextStyle(fontSize: 40)),
          ),
          const Positioned(
            top: 15,
            right: 15,
            child: Text('🌹', style: TextStyle(fontSize: 40)),
          ),
          const Positioned(
            bottom: 15,
            left: 15,
            child: Text('🌹', style: TextStyle(fontSize: 40)),
          ),
          const Positioned(
            bottom: 15,
            right: 15,
            child: Text('🌹', style: TextStyle(fontSize: 40)),
          ),
          // Frame
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.5), width: 2),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.3), width: 1),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Save the Date',
                  style: TextStyle(
                    color: primary,
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'James',
                  style: TextStyle(
                    color: accent,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text('&', style: TextStyle(color: primary, fontSize: 24)),
                Text(
                  'Sarah',
                  style: TextStyle(
                    color: accent,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 100, height: 1, color: primary),
                const SizedBox(height: 16),
                Text(
                  'January 15, 2026',
                  style: TextStyle(color: primary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '4:00 PM',
                  style: TextStyle(
                    color: accent.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Grand Ballroom',
                  style: TextStyle(color: accent, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeArtDecoPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a3a4a), Color(0xFF0d1f2d)],
        ),
      ),
      child: Stack(
        children: [
          // Art deco corners
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary, width: 3),
                  left: BorderSide(color: primary, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary, width: 3),
                  right: BorderSide(color: primary, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary, width: 3),
                  left: BorderSide(color: primary, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary, width: 3),
                  right: BorderSide(color: primary, width: 3),
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'J & S',
                  style: TextStyle(
                    color: primary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TOGETHER WITH THEIR FAMILIES',
                  style: TextStyle(
                    color: primary.withOpacity(0.6),
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'James',
                  style: TextStyle(
                    color: accent,
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text('&', style: TextStyle(color: primary, fontSize: 16)),
                Text(
                  'Sarah',
                  style: TextStyle(
                    color: accent,
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 1, color: primary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '◆',
                        style: TextStyle(color: primary, fontSize: 8),
                      ),
                    ),
                    Container(width: 40, height: 1, color: primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'January 15, 2026',
                  style: TextStyle(
                    color: primary,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '4:00 PM',
                  style: TextStyle(
                    color: accent.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grand Ballroom',
                  style: TextStyle(color: accent, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeCelestialPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF0f0f23)],
        ),
      ),
      child: Stack(
        children: [
          // Stars scattered
          Positioned(
            top: 30,
            left: 40,
            child: Text(
              '✦',
              style: TextStyle(color: primary.withOpacity(0.6), fontSize: 12),
            ),
          ),
          Positioned(
            top: 60,
            right: 50,
            child: Text(
              '✧',
              style: TextStyle(color: primary.withOpacity(0.4), fontSize: 10),
            ),
          ),
          Positioned(
            top: 120,
            left: 60,
            child: Text(
              '✦',
              style: TextStyle(color: primary.withOpacity(0.5), fontSize: 8),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 40,
            child: Text(
              '✧',
              style: TextStyle(color: primary.withOpacity(0.7), fontSize: 14),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 50,
            child: Text(
              '✦',
              style: TextStyle(color: primary.withOpacity(0.5), fontSize: 10),
            ),
          ),
          // Moon
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.nightlight_round, color: primary, size: 50),
            ),
          ),
          // Border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.3), width: 2),
              ),
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SAVE THE DATE',
                    style: TextStyle(
                      color: primary.withOpacity(0.6),
                      fontSize: 12,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'James',
                    style: TextStyle(
                      color: primary,
                      fontSize: 36,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text('&', style: TextStyle(color: accent, fontSize: 20)),
                  Text(
                    'Sarah',
                    style: TextStyle(
                      color: primary,
                      fontSize: 36,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 120,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          primary,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'January 15, 2026',
                    style: TextStyle(
                      color: primary,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4:00 PM',
                    style: TextStyle(
                      color: accent.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Grand Ballroom',
                    style: TextStyle(color: accent, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '✧ ✦ ✧ ✦ ✧',
                    style: TextStyle(
                      color: primary.withOpacity(0.4),
                      fontSize: 10,
                      letterSpacing: 5,
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

  Widget _buildLargeModernGoldPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      color: const Color(0xFFFEFEFE),
      child: Stack(
        children: [
          // Top and bottom gold bars
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 8, color: primary),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 8, color: primary),
          ),
          // Side lines
          Positioned(
            top: 80,
            bottom: 80,
            left: 25,
            child: Container(width: 1, color: primary.withOpacity(0.3)),
          ),
          Positioned(
            top: 80,
            bottom: 80,
            right: 25,
            child: Container(width: 1, color: primary.withOpacity(0.3)),
          ),
          // Monogram
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: primary, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'J&S',
                    style: TextStyle(
                      color: primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Text(
                  'WEDDING INVITATION',
                  style: TextStyle(
                    color: secondary.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Text('James', style: TextStyle(color: secondary, fontSize: 32)),
                Text('&', style: TextStyle(color: primary, fontSize: 20)),
                Text('Sarah', style: TextStyle(color: secondary, fontSize: 32)),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 1, color: primary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '◇',
                        style: TextStyle(color: primary, fontSize: 10),
                      ),
                    ),
                    Container(width: 40, height: 1, color: primary),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'January 15, 2026',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '4:00 PM',
                  style: TextStyle(
                    color: secondary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Grand Ballroom',
                  style: TextStyle(color: secondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Text(
                  '◇ ◇ ◇',
                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    letterSpacing: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeGreeneryPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      color: const Color(0xFFF8F5F0),
      child: Stack(
        children: [
          // Leaf decorations
          const Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text('🌿 🍃 🌿', style: TextStyle(fontSize: 24)),
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text('🌿 🍃 🌿', style: TextStyle(fontSize: 24)),
            ),
          ),
          // Frame
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.3), width: 1),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WEDDING CELEBRATION',
                  style: TextStyle(
                    color: primary.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'James',
                  style: TextStyle(
                    color: primary,
                    fontSize: 36,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text('and', style: TextStyle(color: secondary, fontSize: 16)),
                Text(
                  'Sarah',
                  style: TextStyle(
                    color: primary,
                    fontSize: 36,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 50,
                  height: 1,
                  color: primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'January 15, 2026',
                  style: TextStyle(
                    color: primary,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '4:00 PM',
                  style: TextStyle(
                    color: primary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text('— ❧ —', style: TextStyle(color: secondary, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  'Grand Ballroom',
                  style: TextStyle(color: primary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeAfricanPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      color: accent,
      child: Stack(
        children: [
          // Kente border top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 25,
            child: Row(
              children: List.generate(
                20,
                (i) => Expanded(
                  child: Container(
                    color: [
                      primary,
                      secondary,
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B0000),
                    ][i % 4],
                  ),
                ),
              ),
            ),
          ),
          // Kente border bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 25,
            child: Row(
              children: List.generate(
                20,
                (i) => Expanded(
                  child: Container(
                    color: [
                      primary,
                      secondary,
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B0000),
                    ][i % 4],
                  ),
                ),
              ),
            ),
          ),
          // Side borders
          Positioned(
            top: 25,
            bottom: 25,
            left: 0,
            width: 12,
            child: Column(
              children: List.generate(
                15,
                (i) => Expanded(
                  child: Container(
                    color: [
                      primary,
                      secondary,
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B0000),
                    ][i % 4],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 25,
            bottom: 25,
            right: 0,
            width: 12,
            child: Column(
              children: List.generate(
                15,
                (i) => Expanded(
                  child: Container(
                    color: [
                      primary,
                      secondary,
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B0000),
                    ][i % 4],
                  ),
                ),
              ),
            ),
          ),
          // Inner border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                border: Border.all(color: primary, width: 2),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✦', style: TextStyle(color: primary, fontSize: 28)),
                const SizedBox(height: 10),
                Text(
                  'WEDDING INVITATION',
                  style: TextStyle(
                    color: const Color(0xFF2D1810).withOpacity(0.6),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'James',
                  style: TextStyle(
                    color: const Color(0xFF2D1810),
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text('&', style: TextStyle(color: primary, fontSize: 18)),
                Text(
                  'Sarah',
                  style: TextStyle(
                    color: const Color(0xFF2D1810),
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 30, height: 2, color: primary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '✦',
                        style: TextStyle(color: primary, fontSize: 10),
                      ),
                    ),
                    Container(width: 30, height: 2, color: primary),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'January 15, 2026',
                  style: TextStyle(
                    color: const Color(0xFF2D1810),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '4:00 PM',
                  style: TextStyle(
                    color: const Color(0xFF2D1810).withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Grand Ballroom',
                  style: TextStyle(
                    color: const Color(0xFF2D1810),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New professional preview templates

  Widget _buildLargeColorfulFloralPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      color: const Color(0xFFFDF6F0),
      child: Stack(
        children: [
          // Corner flowers
          Positioned(
            top: 10,
            left: 10,
            child: Text('🌸', style: TextStyle(fontSize: 35)),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Text('🌼', style: TextStyle(fontSize: 35)),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Text('🌻', style: TextStyle(fontSize: 35)),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Text('🌺', style: TextStyle(fontSize: 35)),
          ),
          // Photo circle placeholder
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      primary.withOpacity(0.3),
                      secondary.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Icon(Icons.person, color: Colors.white54, size: 30),
              ),
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Olivia & Jason',
                    style: TextStyle(
                      color: primary,
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'June 14, 2025 • 2:00 PM',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The Creative Commons',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeWatercolorPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFF9F5), const Color(0xFFFFEDE4)],
        ),
      ),
      child: Stack(
        children: [
          // Watercolor blobs
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFADD8E6).withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF90EE90).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDAB9).withOpacity(0.2),
              ),
            ),
          ),
          // Small flowers
          Positioned(
            top: 30,
            left: 40,
            child: Text('🌸', style: TextStyle(fontSize: 24)),
          ),
          Positioned(
            top: 40,
            right: 30,
            child: Text('🌷', style: TextStyle(fontSize: 20)),
          ),
          Positioned(
            bottom: 30,
            left: 50,
            child: Text('🌹', style: TextStyle(fontSize: 22)),
          ),
          Positioned(
            bottom: 40,
            right: 40,
            child: Text('🌺', style: TextStyle(fontSize: 20)),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WEDDING INVITATION',
                  style: TextStyle(
                    color: const Color(0xFFB8860B),
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Isabella',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 36,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  '&',
                  style: TextStyle(
                    color: const Color(0xFFB8860B),
                    fontSize: 24,
                  ),
                ),
                Text(
                  'Alexander',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 36,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 100,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFB8860B),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'August 15, 2025',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Garden Estate',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeRusticPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      color: const Color(0xFFFFFEF9),
      child: Stack(
        children: [
          // Inner border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.5), width: 1),
              ),
            ),
          ),
          // Outer border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4B896), width: 2),
              ),
            ),
          ),
          // Corner leaves
          Positioned(
            top: 20,
            left: 20,
            child: Text('🍃', style: TextStyle(fontSize: 20)),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Text('🌿', style: TextStyle(fontSize: 20)),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Text('🌿', style: TextStyle(fontSize: 20)),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Text('🍃', style: TextStyle(fontSize: 20)),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Together with their families',
                  style: TextStyle(
                    color: const Color(0xFFA08060),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hannah',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text('&', style: TextStyle(color: primary, fontSize: 28)),
                Text(
                  'Michael',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 1, color: primary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '❧',
                        style: TextStyle(color: primary, fontSize: 14),
                      ),
                    ),
                    Container(width: 40, height: 1, color: primary),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'September 21, 2025',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Willow Creek Barn',
                  style: TextStyle(
                    color: const Color(0xFF6B5B4F),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTropicalPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFFBF5), const Color(0xFFFFF8F0)],
        ),
      ),
      child: Stack(
        children: [
          // Tropical leaves top
          Positioned(
            top: 0,
            left: 0,
            child: Text('🌴', style: TextStyle(fontSize: 35)),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Text('🌴', style: TextStyle(fontSize: 35)),
          ),
          Positioned(
            top: 10,
            left: 40,
            child: Text('🌿', style: TextStyle(fontSize: 25)),
          ),
          Positioned(
            top: 10,
            right: 40,
            child: Text('🌿', style: TextStyle(fontSize: 25)),
          ),
          // Flowers
          Positioned(
            top: 50,
            left: 20,
            child: Text('🌺', style: TextStyle(fontSize: 28)),
          ),
          Positioned(
            top: 60,
            right: 25,
            child: Text('🌸', style: TextStyle(fontSize: 24)),
          ),
          // Bottom tropical
          Positioned(
            bottom: 0,
            left: 10,
            child: Text('🌴', style: TextStyle(fontSize: 30)),
          ),
          Positioned(
            bottom: 0,
            right: 10,
            child: Text('🌴', style: TextStyle(fontSize: 30)),
          ),
          Positioned(
            bottom: 10,
            left: 50,
            child: Text('🌺', style: TextStyle(fontSize: 22)),
          ),
          Positioned(
            bottom: 15,
            right: 45,
            child: Text('🌻', style: TextStyle(fontSize: 20)),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "You're Invited",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sophia',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 36,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text('&', style: TextStyle(color: primary, fontSize: 22)),
                Text(
                  'Daniel',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 36,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondary, secondary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '24',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'DECEMBER 2025',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tropical Paradise Resort',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeWinterPreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF0D1B2A), const Color(0xFF1B2838)],
        ),
      ),
      child: Stack(
        children: [
          // Snowflakes
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              '❄',
              style: TextStyle(color: accent.withOpacity(0.5), fontSize: 18),
            ),
          ),
          Positioned(
            top: 30,
            right: 30,
            child: Text(
              '❄',
              style: TextStyle(color: accent.withOpacity(0.4), fontSize: 14),
            ),
          ),
          Positioned(
            top: 60,
            left: 60,
            child: Text(
              '✦',
              style: TextStyle(color: primary.withOpacity(0.4), fontSize: 10),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 25,
            child: Text(
              '❄',
              style: TextStyle(color: accent.withOpacity(0.4), fontSize: 16),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 35,
            child: Text(
              '❄',
              style: TextStyle(color: accent.withOpacity(0.5), fontSize: 12),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 60,
            child: Text(
              '✦',
              style: TextStyle(color: primary.withOpacity(0.4), fontSize: 10),
            ),
          ),
          // Gold corner accents
          Positioned(
            top: 15,
            left: 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary.withOpacity(0.5), width: 1),
                  left: BorderSide(color: primary.withOpacity(0.5), width: 1),
                ),
              ),
            ),
          ),
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary.withOpacity(0.5), width: 1),
                  right: BorderSide(color: primary.withOpacity(0.5), width: 1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary.withOpacity(0.5), width: 1),
                  left: BorderSide(color: primary.withOpacity(0.5), width: 1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary.withOpacity(0.5), width: 1),
                  right: BorderSide(color: primary.withOpacity(0.5), width: 1),
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WEDDING CELEBRATION',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text('❄', style: TextStyle(color: primary, fontSize: 18)),
                const SizedBox(height: 12),
                Text(
                  'Victoria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '&',
                  style: TextStyle(
                    color: primary,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'Christopher',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'December 21, 2025',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5:00 PM',
                        style: TextStyle(color: accent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The Crystal Ballroom',
                  style: TextStyle(color: accent, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeRoyalPreview(Color primary, Color secondary, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1C1C1C), const Color(0xFF0F0F0F)],
        ),
      ),
      child: Stack(
        children: [
          // Gold border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.4), width: 2),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.2), width: 1),
              ),
            ),
          ),
          // Corner ornaments
          Positioned(
            top: 20,
            left: 20,
            child: Text('♔', style: TextStyle(color: primary, fontSize: 16)),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Text('♔', style: TextStyle(color: primary, fontSize: 16)),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Text('⚜', style: TextStyle(color: primary, fontSize: 14)),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Text('⚜', style: TextStyle(color: primary, fontSize: 14)),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown icon
                Text('👑', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'ROYAL WEDDING',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Arabella',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '&',
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'Sebastian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 1,
                      color: primary.withOpacity(0.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '◆',
                        style: TextStyle(color: primary, fontSize: 10),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 1,
                      color: primary.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'November 15, 2025',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Grand Palace Ballroom',
                  style: TextStyle(color: primary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeVintageLacePreview(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      color: const Color(0xFFFFFEF8),
      child: Stack(
        children: [
          // Lace corner patterns
          Positioned(
            top: 15,
            left: 15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary, width: 1),
                  left: BorderSide(color: primary, width: 1),
                ),
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary, width: 1),
                  right: BorderSide(color: primary, width: 1),
                ),
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary, width: 1),
                  left: BorderSide(color: primary, width: 1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary, width: 1),
                  right: BorderSide(color: primary, width: 1),
                ),
              ),
            ),
          ),
          // Inner border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8DED0), width: 1),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Together with their families',
                  style: TextStyle(
                    color: const Color(0xFFA89880),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Charlotte',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  '&',
                  style: TextStyle(
                    color: const Color(0xFFC4A87C),
                    fontSize: 26,
                  ),
                ),
                Text(
                  'William',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 150,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, primary, Colors.transparent],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'October 18, 2025',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rosewood Manor',
                  style: TextStyle(
                    color: const Color(0xFF8B7355),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargePreviewContent(InvitationCardTemplateModel template) {
    final accentColor = _parseColor(template.accentColor);
    final primaryColor = _parseColor(template.primaryColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top decorative element based on category
              _buildLargeTopDecoration(
                template.category,
                accentColor,
                primaryColor,
              ),
              const SizedBox(height: 12),

              // Wedding invitation text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: template.category == 'ELEGANT'
                      ? Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  'WEDDING INVITATION',
                  style: TextStyle(
                    color: accentColor.withOpacity(0.7),
                    fontSize: 9,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Couple names with decorative styling
              Text(
                'John',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 1,
                    color: accentColor.withOpacity(0.4),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '&',
                      style: TextStyle(
                        color: accentColor.withOpacity(0.8),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 1,
                    color: accentColor.withOpacity(0.4),
                  ),
                ],
              ),
              Text(
                'Jane',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Ornate divider
              _buildOrnamentDivider(template.category, accentColor),
              const SizedBox(height: 16),

              // Date section
              Text(
                'SATURDAY',
                style: TextStyle(
                  color: accentColor.withOpacity(0.6),
                  fontSize: 8,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'January 15, 2025',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'at 4:00 PM',
                style: TextStyle(
                  color: accentColor.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),

              // Venue
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: accentColor.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Grand Ballroom',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dar es Salaam, Tanzania',
                      style: TextStyle(
                        color: accentColor.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bottom decoration
              _buildLargeBottomDecoration(template.category, accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeTopDecoration(
    String category,
    Color accent,
    Color primary,
  ) {
    switch (category) {
      case 'FLORAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist, color: accent.withOpacity(0.5), size: 20),
            const SizedBox(width: 8),
            Icon(Icons.local_florist, color: accent.withOpacity(0.7), size: 28),
            Icon(Icons.favorite, color: accent, size: 32),
            Icon(Icons.local_florist, color: accent.withOpacity(0.7), size: 28),
            const SizedBox(width: 8),
            Icon(Icons.local_florist, color: accent.withOpacity(0.5), size: 20),
          ],
        );
      case 'ELEGANT':
        return Column(
          children: [
            Icon(Icons.auto_awesome, color: accent, size: 28),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 60, height: 1, color: accent.withOpacity(0.3)),
                const SizedBox(width: 12),
                Container(width: 60, height: 1, color: accent.withOpacity(0.3)),
              ],
            ),
          ],
        );
      case 'TRADITIONAL':
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: accent.withOpacity(0.6), size: 16),
                const SizedBox(width: 8),
                Icon(Icons.diamond, color: accent, size: 28),
                const SizedBox(width: 8),
                Icon(Icons.star, color: accent.withOpacity(0.6), size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 100,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0),
                    accent,
                    accent.withOpacity(0),
                  ],
                ),
              ),
            ),
          ],
        );
      case 'MINIMALIST':
        return Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 'CULTURAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTribalPattern(accent, 6),
            const SizedBox(width: 12),
            Icon(Icons.favorite, color: accent, size: 28),
            const SizedBox(width: 12),
            _buildTribalPattern(accent, 6),
          ],
        );
      case 'MODERN':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      default:
        return Icon(Icons.favorite, color: accent, size: 32);
    }
  }

  Widget _buildTribalPattern(Color color, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(i == 1 ? 1 : 0.5),
            shape: i == 1 ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
      ),
    );
  }

  Widget _buildOrnamentDivider(String category, Color color) {
    switch (category) {
      case 'FLORAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 40, height: 1, color: color.withOpacity(0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.spa, color: color.withOpacity(0.6), size: 18),
            ),
            Container(width: 40, height: 1, color: color.withOpacity(0.3)),
          ],
        );
      case 'MINIMALIST':
        return Container(width: 100, height: 2, color: color.withOpacity(0.5));
      default:
        return Container(
          width: 120,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0), color, color.withOpacity(0)],
            ),
          ),
        );
    }
  }

  Widget _buildLargeBottomDecoration(String category, Color color) {
    switch (category) {
      case 'FLORAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, color: color.withOpacity(0.4), size: 18),
            const SizedBox(width: 4),
            Icon(Icons.local_florist, color: color.withOpacity(0.5), size: 22),
            const SizedBox(width: 4),
            Icon(Icons.eco, color: color.withOpacity(0.4), size: 18),
          ],
        );
      case 'ELEGANT':
        return Text(
          '❧  ❧  ❧',
          style: TextStyle(
            color: color.withOpacity(0.4),
            fontSize: 14,
            letterSpacing: 8,
          ),
        );
      case 'CULTURAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == 2 ? color : color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      default:
        return Container(
          width: 80,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0),
                color.withOpacity(0.5),
                color.withOpacity(0),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHorizontalTemplateCard(InvitationCardTemplateModel template) {
    final isSelected = _selectedTemplateId == template.id;
    final primaryColor = _parseColor(template.primaryColor);
    final secondaryColor = _parseColor(template.secondaryColor);
    final accentColor = _parseColor(template.accentColor);

    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              // Always use styled mini preview based on template design
              Positioned.fill(
                child: _buildStyledCardPreview(
                  template,
                  primaryColor,
                  secondaryColor,
                  accentColor,
                ),
              ),

              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // Premium badge
              if (template.isPremium)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),

              // Canvas template badge (Canva-style)
              if (template.isCanvasTemplate)
                Positioned(
                  top: template.isPremium ? 32 : 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Template name at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    template.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCardMiniPreview(InvitationCardTemplateModel template) {
    final accentColor = _parseColor(template.accentColor);
    final primaryColor = _parseColor(template.primaryColor);

    // Different card designs based on category
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative element based on category
          _buildCategoryDecoration(template.category, accentColor, 14),
          const SizedBox(height: 2),

          // Mini couple names
          Text(
            'J & J',
            style: TextStyle(
              color: accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
              fontFamily: _getFontFamily(template.fontFamily),
            ),
          ),
          const SizedBox(height: 1),

          // Mini divider
          Container(width: 30, height: 1, color: accentColor.withOpacity(0.5)),
          const SizedBox(height: 1),

          // Mini date
          Text(
            'JAN 15',
            style: TextStyle(
              color: accentColor.withOpacity(0.7),
              fontSize: 7,
              letterSpacing: 1,
            ),
          ),

          // Category-specific decoration at bottom
          const SizedBox(height: 2),
          _buildBottomDecoration(template.category, primaryColor, accentColor),
        ],
      ),
    );
  }

  /// Build a beautiful styled card preview based on template category and colors
  Widget _buildStyledCardPreview(
    InvitationCardTemplateModel template,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    // For Canvas templates, use canvas mini preview
    if (template.isCanvasTemplate) {
      return _buildCanvasMiniPreview(
        template,
        primaryColor,
        secondaryColor,
        accentColor,
      );
    }
    
    // Use different styles based on category/slug
    switch (template.slug) {
      case 'rose-floral-elegance':
      case 'romantic-roses':
        return _buildRoseFloralPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'art-deco-navy':
        return _buildArtDecoPreview(primaryColor, secondaryColor, accentColor);
      case 'celestial-night':
        return _buildCelestialPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'modern-gold':
        return _buildModernGoldPreview(
          primaryColor,
          secondaryColor,
          accentColor,
        );
      case 'greenery-minimal':
        return _buildGreeneryPreview(primaryColor, secondaryColor, accentColor);
      case 'african-heritage':
      case 'swahili-elegance':
        return _buildAfricanPreview(primaryColor, secondaryColor, accentColor);
      default:
        return _buildDefaultPreview(
          template,
          primaryColor,
          secondaryColor,
          accentColor,
        );
    }
  }

  /// Build mini preview for Canvas templates in horizontal card
  Widget _buildCanvasMiniPreview(
    InvitationCardTemplateModel template,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    final style = template.canvasStyle ?? 'elegant';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor, accentColor.withOpacity(0.9)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements based on style
          if (style == 'floral') ...[
            Positioned(top: 4, left: 4, child: Text('🌸', style: TextStyle(fontSize: 10))),
            Positioned(top: 4, right: 4, child: Text('🌺', style: TextStyle(fontSize: 10))),
          ],
          if (style == 'geometric') ...[
            Positioned.fill(
              child: CustomPaint(
                painter: _GeometricPatternPainter(primaryColor.withOpacity(0.15)),
              ),
            ),
          ],
          
          // Border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withOpacity(0.6), width: 1),
              ),
            ),
          ),
          
          // Content - compact layout
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'S & J',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      fontStyle: style == 'elegant' ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 20,
                    height: 1,
                    color: primaryColor.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoseFloralPreview(Color primary, Color secondary, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF2d1515), const Color(0xFF1a0a0a)],
        ),
      ),
      child: Stack(
        children: [
          // Rose corners
          Positioned(
            top: 5,
            left: 5,
            child: Text('🌹', style: TextStyle(fontSize: 16)),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Text('🌹', style: TextStyle(fontSize: 16)),
          ),
          Positioned(
            bottom: 5,
            left: 5,
            child: Text('🌹', style: TextStyle(fontSize: 16)),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Text('🌹', style: TextStyle(fontSize: 16)),
          ),
          // Border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.5), width: 1),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Save the Date',
                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'James & Sarah',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 30,
                  height: 1,
                  color: primary.withOpacity(0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jan 15, 2026',
                  style: TextStyle(color: primary, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtDecoPreview(Color primary, Color secondary, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1a3a4a), const Color(0xFF0d1f2d)],
        ),
      ),
      child: Stack(
        children: [
          // Art deco corners
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary, width: 2),
                  left: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary, width: 2),
                  right: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary, width: 2),
                  left: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary, width: 2),
                  right: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'J & S',
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'James',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text('&', style: TextStyle(color: primary, fontSize: 8)),
                Text(
                  'Sarah',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Container(width: 30, height: 1, color: primary),
                const SizedBox(height: 2),
                Text(
                  'Jan 15',
                  style: TextStyle(
                    color: primary.withOpacity(0.8),
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelestialPreview(Color primary, Color secondary, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1a1a2e), const Color(0xFF0f0f23)],
        ),
      ),
      child: Stack(
        children: [
          // Stars
          Positioned(
            top: 10,
            left: 15,
            child: Text(
              '✦',
              style: TextStyle(color: primary.withOpacity(0.6), fontSize: 8),
            ),
          ),
          Positioned(
            top: 25,
            right: 20,
            child: Text(
              '✧',
              style: TextStyle(color: primary.withOpacity(0.4), fontSize: 6),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 25,
            child: Text(
              '✦',
              style: TextStyle(color: primary.withOpacity(0.5), fontSize: 7),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 15,
            child: Text(
              '✧',
              style: TextStyle(color: primary.withOpacity(0.6), fontSize: 8),
            ),
          ),
          // Moon
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.nightlight_round, color: primary, size: 18),
              ),
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Save the Date',
                    style: TextStyle(
                      color: primary.withOpacity(0.7),
                      fontSize: 8,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'James',
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text('&', style: TextStyle(color: accent, fontSize: 10)),
                  Text(
                    'Sarah',
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '✧ ✦ ✧',
                    style: TextStyle(
                      color: primary.withOpacity(0.5),
                      fontSize: 8,
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

  Widget _buildModernGoldPreview(Color primary, Color secondary, Color accent) {
    return Container(
      color: const Color(0xFFFEFEFE),
      child: Stack(
        children: [
          // Top gold line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 4, color: primary),
          ),
          // Bottom gold line
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 4, color: primary),
          ),
          // Side lines
          Positioned(
            top: 50,
            bottom: 50,
            left: 12,
            child: Container(width: 1, color: primary.withOpacity(0.3)),
          ),
          Positioned(
            top: 50,
            bottom: 50,
            right: 12,
            child: Container(width: 1, color: primary.withOpacity(0.3)),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: primary, width: 1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'J&S',
                    style: TextStyle(
                      color: primary,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text('James', style: TextStyle(color: secondary, fontSize: 10)),
                Text('&', style: TextStyle(color: primary, fontSize: 8)),
                Text('Sarah', style: TextStyle(color: secondary, fontSize: 10)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 1, color: primary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        '◇',
                        style: TextStyle(color: primary, fontSize: 5),
                      ),
                    ),
                    Container(width: 12, height: 1, color: primary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Jan 15',
                  style: TextStyle(
                    color: secondary.withOpacity(0.7),
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeneryPreview(Color primary, Color secondary, Color accent) {
    return Container(
      color: const Color(0xFFF8F5F0),
      child: Stack(
        children: [
          // Leaf decorations
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
          ),
          // Frame
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: primary.withOpacity(0.3), width: 1),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Wedding Celebration',
                  style: TextStyle(
                    color: primary.withOpacity(0.6),
                    fontSize: 7,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'James',
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text('and', style: TextStyle(color: secondary, fontSize: 9)),
                Text(
                  'Sarah',
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 25,
                  height: 1,
                  color: primary.withOpacity(0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jan 15, 2026',
                  style: TextStyle(
                    color: primary.withOpacity(0.7),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfricanPreview(Color primary, Color secondary, Color accent) {
    return Container(
      color: accent,
      child: Stack(
        children: [
          // Kente border pattern (top and bottom)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 10,
            child: Row(
              children: List.generate(
                10,
                (i) => Expanded(
                  child: Container(
                    color: [
                      primary,
                      secondary,
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B0000),
                    ][i % 4],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 10,
            child: Row(
              children: List.generate(
                10,
                (i) => Expanded(
                  child: Container(
                    color: [
                      primary,
                      secondary,
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B0000),
                    ][i % 4],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✦', style: TextStyle(color: primary, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  'James',
                  style: TextStyle(
                    color: const Color(0xFF2D1810),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text('&', style: TextStyle(color: primary, fontSize: 8)),
                Text(
                  'Sarah',
                  style: TextStyle(
                    color: const Color(0xFF2D1810),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jan 15',
                  style: TextStyle(
                    color: const Color(0xFF2D1810).withOpacity(0.7),
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPreview(
    InvitationCardTemplateModel template,
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [secondary, secondary.withOpacity(0.8)],
        ),
      ),
      child: _buildInvitationCardMiniPreview(template),
    );
  }

  Widget _buildCategoryDecoration(String category, Color color, double size) {
    switch (category) {
      case 'FLORAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_florist,
              color: color.withOpacity(0.6),
              size: size - 4,
            ),
            Icon(Icons.favorite, color: color, size: size),
            Icon(
              Icons.local_florist,
              color: color.withOpacity(0.6),
              size: size - 4,
            ),
          ],
        );
      case 'ELEGANT':
        return Icon(Icons.auto_awesome, color: color, size: size);
      case 'TRADITIONAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 20, height: 1, color: color.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.diamond, color: color, size: size),
            ),
            Container(width: 20, height: 1, color: color.withOpacity(0.5)),
          ],
        );
      case 'MINIMALIST':
        return Container(
          width: 30,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      case 'CULTURAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: color.withOpacity(0.6), size: size - 4),
            Icon(Icons.favorite, color: color, size: size),
            Icon(Icons.star, color: color.withOpacity(0.6), size: size - 4),
          ],
        );
      case 'MODERN':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      default:
        return Icon(Icons.favorite, color: color, size: size);
    }
  }

  Widget _buildBottomDecoration(String category, Color primary, Color accent) {
    switch (category) {
      case 'FLORAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, color: accent.withOpacity(0.4), size: 10),
            const SizedBox(width: 8),
            Icon(Icons.eco, color: accent.withOpacity(0.4), size: 10),
          ],
        );
      case 'ELEGANT':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withOpacity(0.3), width: 0.5),
          ),
          child: Text(
            '❧',
            style: TextStyle(color: accent.withOpacity(0.5), fontSize: 8),
          ),
        );
      case 'CULTURAL':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: i == 1 ? accent : accent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String? _getFontFamily(String fontFamily) {
    // Return null to use default, or map to available fonts
    // In production, these would be loaded via Google Fonts
    return null;
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Custom painter for geometric patterns in Canvas template fallback
class _GeometricPatternPainter extends CustomPainter {
  final Color color;

  _GeometricPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw diagonal lines
    const spacing = 30.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    
    // Draw corner accents
    final cornerPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Top-left corner
    final cornerSize = size.width * 0.15;
    canvas.drawLine(Offset(20, 20), Offset(20 + cornerSize, 20), cornerPaint);
    canvas.drawLine(Offset(20, 20), Offset(20, 20 + cornerSize), cornerPaint);
    
    // Top-right corner
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20 - cornerSize, 20), cornerPaint);
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20, 20 + cornerSize), cornerPaint);
    
    // Bottom-left corner
    canvas.drawLine(Offset(20, size.height - 20), Offset(20 + cornerSize, size.height - 20), cornerPaint);
    canvas.drawLine(Offset(20, size.height - 20), Offset(20, size.height - 20 - cornerSize), cornerPaint);
    
    // Bottom-right corner
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20 - cornerSize, size.height - 20), cornerPaint);
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20, size.height - 20 - cornerSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}