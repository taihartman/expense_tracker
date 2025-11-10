import 'package:decimal/decimal.dart';
import '../../../expenses/domain/models/expense.dart';
import '../models/transfer_breakdown.dart';

/// Service for calculating how expenses contribute to a specific transfer
class TransferBreakdownCalculator {
  /// Calculate breakdown showing which expenses contribute to a transfer
  ///
  /// With pairwise netting, each transfer directly corresponds to the raw
  /// expenses between two people. This breakdown shows exactly how much
  /// each expense contributed to the debt, with no scaling or optimization.
  TransferBreakdown calculateBreakdown({
    required String fromUserId,
    required String toUserId,
    required Decimal transferAmount,
    required List<Expense> expenses,
  }) {
    final expenseBreakdowns = <ExpenseBreakdown>[];

    // Calculate raw net contributions for each expense
    for (final expense in expenses) {
      // Calculate what each person paid and owes for this expense
      // For itemized expenses, use pre-calculated participantAmounts
      // For equal/weighted expenses, calculate shares
      final Map<String, Decimal> shares;
      if (expense.participantAmounts != null &&
          expense.participantAmounts!.isNotEmpty) {
        shares = expense.participantAmounts!;
      } else {
        shares = expense.calculateShares();
      }

      final fromPaid = expense.payerUserId == fromUserId
          ? expense.amount
          : Decimal.zero;

      final toPaid = expense.payerUserId == toUserId
          ? expense.amount
          : Decimal.zero;

      final fromOwes = shares[fromUserId] ?? Decimal.zero;
      final toOwes = shares[toUserId] ?? Decimal.zero;

      // Calculate direct pairwise debt contribution: how much FROM owes TO from this expense
      //
      // This represents the actual debt created between these two people
      // (ignoring any third parties involved in the expense)
      //
      // Examples:
      // - If TO paid and FROM participated: FROM owes their share to TO (positive)
      // - If FROM paid and TO participated: TO owes their share to FROM (negative)
      // - If neither paid (third party): no debt between FROM and TO (zero)
      final netContribution = _calculateDirectPairwiseDebt(
        expense: expense,
        fromUserId: fromUserId,
        toUserId: toUserId,
        fromOwes: fromOwes,
        toOwes: toOwes,
      );

      expenseBreakdowns.add(
        ExpenseBreakdown(
          expense: expense,
          fromPaid: fromPaid,
          fromOwes: fromOwes,
          toPaid: toPaid,
          toOwes: toOwes,
          netContribution: netContribution,
        ),
      );
    }

    return TransferBreakdown(
      fromUserId: fromUserId,
      toUserId: toUserId,
      totalAmount: transferAmount,
      expenseBreakdowns: expenseBreakdowns,
    );
  }

  /// Calculate the direct pairwise debt between FROM and TO for a specific expense
  ///
  /// This calculates how much FROM owes TO directly from this expense,
  /// focusing only on the debt between these two people.
  ///
  /// Returns:
  /// - Positive: FROM owes TO (increases FROM->TO debt)
  /// - Negative: TO owes FROM (decreases FROM->TO debt)
  /// - Zero: No direct debt between them
  Decimal _calculateDirectPairwiseDebt({
    required Expense expense,
    required String fromUserId,
    required String toUserId,
    required Decimal fromOwes,
    required Decimal toOwes,
  }) {
    if (expense.payerUserId == toUserId) {
      // TO paid the expense: FROM owes their share to TO
      return fromOwes;
    } else if (expense.payerUserId == fromUserId) {
      // FROM paid the expense: TO owes their share to FROM
      // (negative contribution - reduces FROM->TO debt)
      return -toOwes;
    } else {
      // Third party paid: no direct debt between FROM and TO
      return Decimal.zero;
    }
  }
}
