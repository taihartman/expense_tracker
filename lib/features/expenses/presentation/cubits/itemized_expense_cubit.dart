import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/line_item.dart';
import '../../domain/models/item_assignment.dart';
import '../../domain/models/extras.dart';
import '../../domain/models/tax_extra.dart';
import '../../domain/models/tip_extra.dart';
import '../../domain/models/fee_extra.dart';
import '../../domain/models/discount_extra.dart';
import '../../domain/models/allocation_rule.dart';
import '../../domain/models/rounding_config.dart';
import '../../domain/models/percent_base.dart';
import '../../domain/models/absolute_split_mode.dart';
import '../../domain/models/rounding_mode.dart';
import '../../domain/models/remainder_distribution_mode.dart';
import '../../domain/models/expense.dart';
import '../../domain/services/itemized_calculator.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import 'itemized_expense_state.dart';

/// Cubit for managing itemized expense creation/editing
///
/// Handles draft state, validation, calculation, and persistence
class ItemizedExpenseCubit extends Cubit<ItemizedExpenseState> {
  final ExpenseRepository _expenseRepository;
  final ItemizedCalculator _calculator;

  ItemizedExpenseCubit({
    required ExpenseRepository expenseRepository,
    ItemizedCalculator? calculator,
  }) : _expenseRepository = expenseRepository,
       _calculator = calculator ?? ItemizedCalculator(),
       super(const ItemizedExpenseInitial());

  /// Initialize a new itemized expense
  ///
  /// Sets up initial draft state with trip context
  void init({
    required String tripId,
    required List<String> participants,
    String? payerUserId,
    required CurrencyCode currency,
  }) {
    debugPrint('🟡 [Cubit] init() called');
    debugPrint('🟡 [Cubit] tripId: $tripId');
    debugPrint('🟡 [Cubit] participants: $participants');
    debugPrint('🟡 [Cubit] payerUserId: $payerUserId');
    debugPrint('🟡 [Cubit] currency: $currency');

    final currencyCode = currency.code;
    debugPrint('🟡 [Cubit] currencyCode: $currencyCode');

    // Create default allocation rule based on currency
    final precision = _getPrecisionForCurrency(currencyCode);
    debugPrint('🟡 [Cubit] precision for $currencyCode: $precision');

    final defaultAllocation = AllocationRule(
      percentBase: PercentBase.preTaxItemSubtotals,
      absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
      rounding: RoundingConfig(
        precision: precision,
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.largestShare,
      ),
    );

    // Create empty extras
    final emptyExtras = const Extras(
      tax: null,
      tip: null,
      fees: [],
      discounts: [],
    );

    debugPrint('🟡 [Cubit] Emitting ItemizedExpenseEditing state...');
    emit(
      ItemizedExpenseEditing(
        tripId: tripId,
        participants: participants,
        payerUserId: payerUserId,
        currencyCode: currencyCode,
        items: const [],
        extras: emptyExtras,
        allocation: defaultAllocation,
      ),
    );
    debugPrint('🟡 [Cubit] State emitted successfully');
  }

  /// Initialize from existing expense (edit mode)
  ///
  /// Loads existing expense data into editing state
  void initFromExpense({
    required Expense expense,
    required List<String> participants,
  }) {
    debugPrint('🟡 [Cubit] initFromExpense() called');
    debugPrint('🟡 [Cubit] expenseId: ${expense.id}');
    debugPrint('🟡 [Cubit] splitType: ${expense.splitType}');

    // Validate that this is an itemized expense
    if (expense.splitType != SplitType.itemized) {
      debugPrint('🔴 [Cubit] ERROR: Expense is not itemized!');
      emit(ItemizedExpenseError('Cannot edit: expense is not itemized', state));
      return;
    }

    // Validate that itemized fields exist
    if (expense.items == null || expense.items!.isEmpty) {
      debugPrint('🔴 [Cubit] ERROR: Expense has no items!');
      emit(ItemizedExpenseError('Cannot edit: expense has no items', state));
      return;
    }

    debugPrint('🟡 [Cubit] Loading ${expense.items!.length} items');
    debugPrint('🟡 [Cubit] Payer: ${expense.payerUserId}');
    debugPrint('🟡 [Cubit] Currency: ${expense.currency.code}');

    // Use existing allocation or create default
    final allocation =
        expense.allocation ??
        AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: _getPrecisionForCurrency(expense.currency.code),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

    // Use existing extras or create empty
    final extras =
        expense.extras ??
        const Extras(tax: null, tip: null, fees: [], discounts: []);

    debugPrint(
      '🟡 [Cubit] Emitting ItemizedExpenseEditing state (edit mode)...',
    );
    emit(
      ItemizedExpenseEditing(
        expenseId: expense.id,
        tripId: expense.tripId,
        participants: participants,
        payerUserId: expense.payerUserId,
        currencyCode: expense.currency.code,
        items: List.from(expense.items!), // Copy list
        extras: extras,
        allocation: allocation,
        originalDate: expense.date,
        originalDescription: expense.description,
        originalCategoryId: expense.categoryId,
        originalCreatedAt: expense.createdAt,
      ),
    );
    debugPrint('🟡 [Cubit] State emitted successfully (edit mode)');

    // Trigger validation and calculation
    _validateAndCalculate();
  }

  /// Update the payer for the expense
  void setPayer(String payerUserId) {
    debugPrint('🟡 [Cubit] setPayer() called with: $payerUserId');
    final current = _getCurrentEditingState();
    if (current == null) {
      debugPrint('🟡 [Cubit] No current editing state, cannot set payer');
      return;
    }

    if (current.payerUserId == payerUserId) {
      debugPrint(
        '🟡 [Cubit] Payer already set to $payerUserId, no change needed',
      );
      return;
    }

    final updatedState = current.copyWith(payerUserId: payerUserId);
    emit(updatedState);
    debugPrint('🟡 [Cubit] Payer updated to $payerUserId');
    // Recalculate in case remainder distribution mode uses payer
    _validateAndCalculate();
  }

  /// Add a new line item
  void addItem(LineItem item) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final updatedItems = List<LineItem>.from(current.items)..add(item);
    final updatedState = current.copyWith(items: updatedItems);

    emit(updatedState);
    _validateAndCalculate();
  }

  /// Update an existing line item
  void updateItem(String itemId, LineItem updatedItem) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final itemIndex = current.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final updatedItems = List<LineItem>.from(current.items);
    updatedItems[itemIndex] = updatedItem;

    final updatedState = current.copyWith(items: updatedItems);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Remove a line item
  void removeItem(String itemId) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final updatedItems = current.items
        .where((item) => item.id != itemId)
        .toList();
    final updatedState = current.copyWith(items: updatedItems);

    emit(updatedState);
    _validateAndCalculate();
  }

  /// Update item assignment
  void assignItem(String itemId, ItemAssignment assignment) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final itemIndex = current.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = current.items[itemIndex];
    final updatedItem = LineItem(
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      taxable: item.taxable,
      serviceChargeable: item.serviceChargeable,
      assignment: assignment,
    );

    updateItem(itemId, updatedItem);
  }

  /// Set tax configuration
  void setTax(TaxExtra? tax) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final updatedExtras = Extras(
      tax: tax,
      tip: current.extras.tip,
      fees: current.extras.fees,
      discounts: current.extras.discounts,
    );

    final updatedState = current.copyWith(extras: updatedExtras);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Set tip configuration
  void setTip(TipExtra? tip) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final updatedExtras = Extras(
      tax: current.extras.tax,
      tip: tip,
      fees: current.extras.fees,
      discounts: current.extras.discounts,
    );

    final updatedState = current.copyWith(extras: updatedExtras);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Add a fee
  void addFee(FeeExtra fee) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final updatedFees = List<FeeExtra>.from(current.extras.fees)..add(fee);
    final updatedExtras = Extras(
      tax: current.extras.tax,
      tip: current.extras.tip,
      fees: updatedFees,
      discounts: current.extras.discounts,
    );

    final updatedState = current.copyWith(extras: updatedExtras);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Remove a fee
  void removeFee(int index) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    if (index < 0 || index >= current.extras.fees.length) return;

    final updatedFees = List<FeeExtra>.from(current.extras.fees)
      ..removeAt(index);
    final updatedExtras = Extras(
      tax: current.extras.tax,
      tip: current.extras.tip,
      fees: updatedFees,
      discounts: current.extras.discounts,
    );

    final updatedState = current.copyWith(extras: updatedExtras);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Add a discount
  void addDiscount(DiscountExtra discount) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final updatedDiscounts = List<DiscountExtra>.from(current.extras.discounts)
      ..add(discount);
    final updatedExtras = Extras(
      tax: current.extras.tax,
      tip: current.extras.tip,
      fees: current.extras.fees,
      discounts: updatedDiscounts,
    );

    final updatedState = current.copyWith(extras: updatedExtras);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Remove a discount
  void removeDiscount(int index) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    if (index < 0 || index >= current.extras.discounts.length) return;

    final updatedDiscounts = List<DiscountExtra>.from(current.extras.discounts)
      ..removeAt(index);
    final updatedExtras = Extras(
      tax: current.extras.tax,
      tip: current.extras.tip,
      fees: current.extras.fees,
      discounts: updatedDiscounts,
    );

    final updatedState = current.copyWith(extras: updatedExtras);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Update allocation rules
  void setAllocation(AllocationRule allocation) {
    final current = _getCurrentEditingState();
    if (current == null) return;

    final updatedState = current.copyWith(allocation: allocation);
    emit(updatedState);
    _validateAndCalculate();
  }

  /// Save the expense
  Future<void> save() async {
    if (state is! ItemizedExpenseReady) {
      emit(ItemizedExpenseError('Cannot save: expense not ready', state));
      return;
    }

    final readyState = state as ItemizedExpenseReady;

    if (!readyState.canSave) {
      emit(ItemizedExpenseError('Cannot save: validation errors exist', state));
      return;
    }

    // Validate payer is selected
    if (readyState.draft.payerUserId == null) {
      emit(ItemizedExpenseError('Cannot save: payer not selected', state));
      return;
    }

    emit(ItemizedExpenseSaving(readyState));

    try {
      final isEditMode = readyState.draft.isEditMode;
      debugPrint('🟡 [Cubit] Save mode: ${isEditMode ? "EDIT" : "CREATE"}');

      // Build Expense entity
      final expense = Expense(
        id:
            readyState.draft.expenseId ??
            '', // Use existing ID or empty for new
        tripId: readyState.draft.tripId,
        date: readyState.draft.originalDate ?? DateTime.now(),
        payerUserId: readyState.draft.payerUserId!,
        currency:
            CurrencyCode.fromString(readyState.draft.currencyCode) ??
            CurrencyCode.usd,
        amount: readyState.grandTotal,
        description:
            readyState.draft.originalDescription ??
            _generateDescription(readyState.draft.items),
        categoryId: readyState.draft.originalCategoryId,
        splitType: SplitType.itemized,
        participants: {
          // Only include participants who have items assigned
          for (final participantId in readyState.participantBreakdown.keys)
            participantId: 1, // Simple 1:1 participation weight for itemized
        },
        createdAt: readyState.draft.originalCreatedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        // Itemized fields
        items: readyState.draft.items,
        extras: readyState.draft.extras,
        allocation: readyState.draft.allocation,
        participantAmounts: readyState.participantAmounts,
        participantBreakdown: readyState.participantBreakdown,
      );

      // Save via repository (update or create)
      final Expense savedExpense;
      if (isEditMode) {
        debugPrint('🟡 [Cubit] Updating expense: ${expense.id}');
        savedExpense = await _expenseRepository.updateExpense(expense);
        debugPrint('🟡 [Cubit] Expense updated successfully');
      } else {
        debugPrint('🟡 [Cubit] Creating new expense');
        savedExpense = await _expenseRepository.createExpense(expense);
        debugPrint('🟡 [Cubit] Expense created successfully');
      }

      emit(ItemizedExpenseSaved(savedExpense));
    } catch (e) {
      debugPrint('🔴 [Cubit] Save error: $e');
      emit(ItemizedExpenseError('Failed to save expense: $e', readyState));
    }
  }

  /// Validate and calculate breakdown
  Future<void> _validateAndCalculate() async {
    final current = _getCurrentEditingState();
    if (current == null) return;

    // Run validation
    final validationErrors = <String>[];
    final validationWarnings = <String>[];

    if (current.items.isEmpty) {
      validationErrors.add('At least one item is required');
    }

    // Check for unassigned items
    final unassignedItems = current.items
        .where((item) => item.assignment.users.isEmpty)
        .toList();
    if (unassignedItems.isNotEmpty) {
      validationErrors.add(
        '${unassignedItems.length} item(s) not assigned to anyone',
      );
    }

    // Check for extreme percentages (warning only)
    if (current.extras.tax != null &&
        current.extras.tax!.type == 'percent' &&
        current.extras.tax!.value > Decimal.fromInt(50)) {
      validationWarnings.add(
        'Tax percentage is unusually high (${current.extras.tax!.value}%)',
      );
    }
    if (current.extras.tip != null &&
        current.extras.tip!.type == 'percent' &&
        current.extras.tip!.value > Decimal.fromInt(100)) {
      validationWarnings.add(
        'Tip percentage is unusually high (${current.extras.tip!.value}%)',
      );
    }

    // Update editing state with validation results
    final validatedState = current.copyWith(
      validationErrors: validationErrors,
      validationWarnings: validationWarnings,
    );

    emit(validatedState);

    // If validation failed, don't calculate
    if (validationErrors.isNotEmpty) {
      return;
    }

    // Emit calculating state
    emit(ItemizedExpenseCalculating(validatedState));

    try {
      // Run calculation
      final participantBreakdown = _calculator.calculate(
        items: validatedState.items,
        extras: validatedState.extras,
        allocation: validatedState.allocation,
        currencyCode: validatedState.currencyCode,
      );

      // Extract participant amounts
      final participantAmounts = <String, Decimal>{};
      for (final entry in participantBreakdown.entries) {
        participantAmounts[entry.key] = entry.value.total;
      }

      // Calculate grand total
      final grandTotal = participantAmounts.values.fold(
        Decimal.zero,
        (sum, amount) => sum + amount,
      );

      // Emit ready state
      emit(
        ItemizedExpenseReady(
          draft: validatedState,
          participantBreakdown: participantBreakdown,
          participantAmounts: participantAmounts,
          grandTotal: grandTotal,
        ),
      );
    } catch (e) {
      emit(ItemizedExpenseError('Calculation error: $e', validatedState));
    }
  }

  /// Get current editing state (or null if not editing)
  ItemizedExpenseEditing? _getCurrentEditingState() {
    if (state is ItemizedExpenseEditing) {
      return state as ItemizedExpenseEditing;
    } else if (state is ItemizedExpenseCalculating) {
      return (state as ItemizedExpenseCalculating).draft;
    } else if (state is ItemizedExpenseReady) {
      return (state as ItemizedExpenseReady).draft;
    }
    return null;
  }

  /// Get precision for currency
  Decimal _getPrecisionForCurrency(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'VND':
      case 'JPY':
      case 'KRW':
        return Decimal.one; // 0 decimal places
      case 'BHD':
      case 'JOD':
      case 'KWD':
      case 'OMR':
      case 'TND':
        return Decimal.parse('0.001'); // 3 decimal places
      default:
        return Decimal.parse('0.01'); // 2 decimal places (most currencies)
    }
  }

  /// Generate expense description from items
  String _generateDescription(List<LineItem> items) {
    if (items.isEmpty) {
      return 'Itemized expense';
    }
    if (items.length == 1) {
      return items.first.name;
    }
    if (items.length == 2) {
      return '${items[0].name} and ${items[1].name}';
    }
    return '${items[0].name}, ${items[1].name}, and ${items.length - 2} more';
  }
}
