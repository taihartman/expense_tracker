/// Category domain entity
///
/// Classifies expenses for spending analysis
class Category {
  /// Unique identifier (auto-generated or predefined)
  final String id;

  /// Trip this category belongs to
  final String tripId;

  /// Display name (e.g., "Meals", "Transport")
  /// Required, 1-50 characters, unique per trip
  final String name;

  /// Optional Material icon name (e.g., "restaurant", "directions_car")
  final String? icon;

  /// Optional hex color code (e.g., "#FF5722")
  final String? color;

  const Category({
    required this.id,
    required this.tripId,
    required this.name,
    this.icon,
    this.color,
  });

  /// Validation rules for category creation/update
  String? validate() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Category name cannot be empty';
    }
    if (trimmedName.length > 50) {
      return 'Category name cannot exceed 50 characters';
    }

    // Validate color format if provided
    if (color != null) {
      final hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
      if (!hexColorRegex.hasMatch(color!)) {
        return 'Color must be a valid hex code (e.g., #FF5722)';
      }
    }

    return null;
  }

  /// Create a copy of this category with updated fields
  Category copyWith({
    String? id,
    String? tripId,
    String? name,
    String? icon,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, tripId: $tripId, name: $name, '
        'icon: $icon, color: $color)';
  }
}
