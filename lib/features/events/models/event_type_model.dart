class EventTypeModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String color;
  final bool isActive;

  EventTypeModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.icon = '',
    this.color = '',
    this.isActive = true,
  });

  factory EventTypeModel.fromJson(Map<String, dynamic> json) {
    return EventTypeModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'color': color,
      'is_active': isActive,
    };
  }
}
