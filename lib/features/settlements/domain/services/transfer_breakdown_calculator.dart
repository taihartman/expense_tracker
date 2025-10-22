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
      final shares = expense.calculateShares();

      final fromPaid = expense.payerUserId == fromUserId
          ? expense.amount
          : Decimal.zero;

      final toPaid = expense.payerUserId == toUserId
          ? expense.amount
          : Decimal.zero;

      final fromOwes = shares[fromUserId] ?? Decimal.zero;
      final toOwes = shares[toUserId] ?? Decimal.zero;

      // Calculate net contribution to the transfer FROM -> TO
      // This represents how this expense changed the debt between these two people
      //
      // Net contribution = (what FROM owes - what FROM paid) - (what TO owes - what TO paid)
      //
      // Examples:
      // - If FROM owes $10 but paid $0, and TO owes $0 but paid $20:
      //   Net = (10 - 0) - (0 - 20) = 10 + 20 = +30 (FROM owes TO more)
      // - If TO paid and FROM participated:
      //   FROM owes TO, so positive contribution
      // - If FROM paid and TO participated:
      //   TO owes FROM, so negative contribution (reduces debt)
      final fromNet = fromOwes - fromPaid;
      final toNet = toOwes - toPaid;
      final netContribution = fromNet - toNet;

      expenseBreakdowns.add(ExpenseBreakdown(
        expense: expense,
        fromPaid: fromPaid,
        fromOwes: fromOwes,
        toPaid: toPaid,
        toOwes: toOwes,
        netContribution: netContribution,
      ));
    }

    return TransferBreakdown(
      fromUserId: fromUserId,
      toUserId: toUserId,
      totalAmount: transferAmount,
      expenseBreakdowns: expenseBreakdowns,
    );
  }
}
