/// Category domain entity
///
/// Represents a category in the global shared pool.
/// Categories are used to classify expenses for spending analysis.
/// This is a global collection shared across all trips and users.
class Category {
  /// Unique identifier (Firestore document ID)
  final String id;

  /// Display name (e.g., "Meals", "Transport")
  /// Required, 1-50 characters, unique globally (case-insensitive)
  final String name;

  /// Lowercase version of name for case-insensitive search and duplicate detection
  /// Auto-generated from name
  final String nameLowercase;

  /// Material icon name (e.g., "restaurant", "directions_car")
  /// Defaults to "label" if not specified
  final String icon;

  /// Hex color code (e.g., "#FF5722")
  /// Required for visual categorization
  final String color;

  /// Number of times this category has been used (assigned to expenses)
  /// Incremented each time the category is assigned to an expense
  /// Used to determine popularity for top categories display
  final int usageCount;

  /// Timestamp when category was created
  final DateTime createdAt;

  /// Timestamp when category was last updated (usage increment, etc.)
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    String? nameLowercase,
    this.icon = 'label', // Default icon
    required this.color,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  }) : nameLowercase =
           nameLowercase ?? name.toLowerCase(); // Auto-generate if not provided

  /// Validation rules for category creation/update
  ///
  /// Returns null if valid, error message otherwise.
  /// Note: Full validation is handled by CategoryValidator in core/validators
  String? validate() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Category name cannot be empty';
    }
    if (trimmedName.length > 50) {
      return 'Category name must be 50 characters or less';
    }

    // Validate color format
    final hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!hexColorRegex.hasMatch(color)) {
      return 'Color must be a valid hex code (e.g., #FF5722)';
    }

    // Validate usage count
    if (usageCount < 0) {
      return 'Usage count cannot be negative';
    }

    return null;
  }

  /// Increment the usage count
  ///
  /// Returns a new Category with incremented usageCount and updated timestamp
  Category incrementUsage() {
    return copyWith(usageCount: usageCount + 1, updatedAt: DateTime.now());
  }

  /// Create a copy of this category with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? nameLowercase,
    String? icon,
    String? color,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLowercase:
          nameLowercase ??
          (name != null ? name.toLowerCase() : this.nameLowercase),
      icon: icon ?? this.icon,
      color: color ?? this.color,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    return 'Category(id: $id, name: $name, nameLowercase: $nameLowercase, '
        'icon: $icon, color: $color, usageCount: $usageCount, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
