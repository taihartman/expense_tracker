import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/line_item.dart';
import '../../domain/models/extras.dart';
import '../../domain/models/allocation_rule.dart';
import '../../domain/models/participant_breakdown.dart';

/// Base state for ItemizedExpenseCubit
abstract class ItemizedExpenseState extends Equatable {
  const ItemizedExpenseState();

  @override
  List<Object?> get props => [];
}

/// Initial state before starting itemized expense creation
class ItemizedExpenseInitial extends ItemizedExpenseState {
  const ItemizedExpenseInitial();
}

/// User is editing the draft expense
///
/// Contains current draft data and validation errors
class ItemizedExpenseEditing extends ItemizedExpenseState {
  /// Expense ID (null for new expense, non-null for editing existing)
  final String? expenseId;

  /// Trip ID
  final String tripId;

  /// Participant user IDs (from trip)
  final List<String> participants;

  /// Payer user ID (null if not yet selected)
  final String? payerUserId;

  /// Currency code (USD, VND, etc.)
  final String currencyCode;

  /// Line items
  final List<LineItem> items;

  /// Extras (tax, tip, fees, discounts)
  final Extras extras;

  /// Allocation rules
  final AllocationRule allocation;

  /// Validation errors (empty if valid)
  final List<String> validationErrors;

  /// Validation warnings (non-blocking)
  final List<String> validationWarnings;

  /// Original date (for edit mode, to preserve)
  final DateTime? originalDate;

  /// Original description (for edit mode, to preserve)
  final String? originalDescription;

  /// Original category ID (for edit mode, to preserve)
  final String? originalCategoryId;

  /// Original created timestamp (for edit mode, to preserve)
  final DateTime? originalCreatedAt;

  const ItemizedExpenseEditing({
    this.expenseId,
    required this.tripId,
    required this.participants,
    required this.payerUserId,
    required this.currencyCode,
    required this.items,
    required this.extras,
    required this.allocation,
    this.validationErrors = const [],
    this.validationWarnings = const [],
    this.originalDate,
    this.originalDescription,
    this.originalCategoryId,
    this.originalCreatedAt,
  });

  /// Check if state is valid (no blocking errors)
  bool get isValid => validationErrors.isEmpty;

  /// Check if all items are assigned
  bool get allItemsAssigned =>
      items.every((item) => item.assignment.users.isNotEmpty);

  /// Check if this is edit mode (vs create mode)
  bool get isEditMode => expenseId != null;

  ItemizedExpenseEditing copyWith({
    String? expenseId,
    String? tripId,
    List<String>? participants,
    String? payerUserId,
    String? currencyCode,
    List<LineItem>? items,
    Extras? extras,
    AllocationRule? allocation,
    List<String>? validationErrors,
    List<String>? validationWarnings,
    DateTime? originalDate,
    String? originalDescription,
    String? originalCategoryId,
    DateTime? originalCreatedAt,
  }) {
    return ItemizedExpenseEditing(
      expenseId: expenseId ?? this.expenseId,
      tripId: tripId ?? this.tripId,
      participants: participants ?? this.participants,
      payerUserId: payerUserId ?? this.payerUserId,
      currencyCode: currencyCode ?? this.currencyCode,
      items: items ?? this.items,
      extras: extras ?? this.extras,
      allocation: allocation ?? this.allocation,
      validationErrors: validationErrors ?? this.validationErrors,
      validationWarnings: validationWarnings ?? this.validationWarnings,
      originalDate: originalDate ?? this.originalDate,
      originalDescription: originalDescription ?? this.originalDescription,
      originalCategoryId: originalCategoryId ?? this.originalCategoryId,
      originalCreatedAt: originalCreatedAt ?? this.originalCreatedAt,
    );
  }

  @override
  List<Object?> get props => [
    expenseId,
    tripId,
    participants,
    payerUserId,
    currencyCode,
    items,
    extras,
    allocation,
    validationErrors,
    validationWarnings,
    originalDate,
    originalDescription,
    originalCategoryId,
    originalCreatedAt,
  ];
}

/// Calculation in progress
///
/// Shows loading state while ItemizedCalculator is running
class ItemizedExpenseCalculating extends ItemizedExpenseState {
  /// Draft state that triggered calculation
  final ItemizedExpenseEditing draft;

  const ItemizedExpenseCalculating(this.draft);

  @override
  List<Object?> get props => [draft];
}

/// Calculation complete, ready to save
///
/// Contains calculated breakdown and grand total
class ItemizedExpenseReady extends ItemizedExpenseState {
  /// Draft state
  final ItemizedExpenseEditing draft;

  /// Calculated participant breakdown
  final Map<String, ParticipantBreakdown> participantBreakdown;

  /// Calculated participant amounts (for settlements)
  final Map<String, Decimal> participantAmounts;

  /// Grand total
  final Decimal grandTotal;

  const ItemizedExpenseReady({
    required this.draft,
    required this.participantBreakdown,
    required this.participantAmounts,
    required this.grandTotal,
  });

  /// Check if ready to save (no blocking validation errors)
  bool get canSave => draft.isValid;

  @override
  List<Object?> get props => [
    draft,
    participantBreakdown,
    participantAmounts,
    grandTotal,
  ];
}

/// Saving expense to Firestore
class ItemizedExpenseSaving extends ItemizedExpenseState {
  /// Ready state being saved
  final ItemizedExpenseReady readyState;

  const ItemizedExpenseSaving(this.readyState);

  @override
  List<Object?> get props => [readyState];
}

/// Expense saved successfully
class ItemizedExpenseSaved extends ItemizedExpenseState {
  /// Saved expense
  final Expense expense;

  const ItemizedExpenseSaved(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Error state (validation or save error)
class ItemizedExpenseError extends ItemizedExpenseState {
  /// Error message
  final String message;

  /// Previous state (to allow recovery)
  final ItemizedExpenseState? previousState;

  const ItemizedExpenseError(this.message, [this.previousState]);

  @override
  List<Object?> get props => [message, previousState];
}
