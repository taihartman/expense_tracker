import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Spending breakdown for a single category
class CategorySpending extends Equatable {
  final String categoryId;
  final String categoryName;
  final Decimal amount;
  final String? color; // Hex color from category
  final String? icon; // Icon name from category

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.color,
    this.icon,
  });

  /// Factory constructor from map
  factory CategorySpending.fromMap(Map<String, dynamic> map) {
    return CategorySpending(
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
      amount: Decimal.parse(map['amount'] as String),
      color: map['color'] as String?,
      icon: map['icon'] as String?,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount.toString(),
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
    };
  }

  @override
  List<Object?> get props => [categoryId, categoryName, amount, color, icon];
}

/// Per-person category spending breakdown
class PersonCategorySpending extends Equatable {
  final String userId;
  final Decimal totalPaidBase;
  final Decimal totalOwedBase;
  final Decimal netBase;
  final List<CategorySpending> categoryBreakdown;

  const PersonCategorySpending({
    required this.userId,
    required this.totalPaidBase,
    required this.totalOwedBase,
    required this.netBase,
    required this.categoryBreakdown,
  });

  /// Get total spending across all categories
  Decimal get totalCategorySpending {
    return categoryBreakdown.fold(
      Decimal.zero,
      (sum, category) => sum + category.amount,
    );
  }

  /// Get spending for a specific category
  Decimal getSpendingForCategory(String categoryId) {
    try {
      return categoryBreakdown
          .firstWhere((c) => c.categoryId == categoryId)
          .amount;
    } catch (e) {
      return Decimal.zero;
    }
  }

  /// Factory constructor from map
  factory PersonCategorySpending.fromMap(
    String userId,
    Map<String, dynamic> map,
  ) {
    return PersonCategorySpending(
      userId: userId,
      totalPaidBase: Decimal.parse(map['totalPaidBase'] as String),
      totalOwedBase: Decimal.parse(map['totalOwedBase'] as String),
      netBase: Decimal.parse(map['netBase'] as String),
      categoryBreakdown: (map['categoryBreakdown'] as List<dynamic>)
          .map((item) => CategorySpending.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'totalPaidBase': totalPaidBase.toString(),
      'totalOwedBase': totalOwedBase.toString(),
      'netBase': netBase.toString(),
      'categoryBreakdown': categoryBreakdown.map((c) => c.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    userId,
    totalPaidBase,
    totalOwedBase,
    netBase,
    categoryBreakdown,
  ];
}
