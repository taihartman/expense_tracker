import 'package:decimal/decimal.dart';
import '../../../expenses/domain/models/expense.dart';
import '../models/transfer_breakdown.dart';

/// Service for calculating how expenses contribute to a specific transfer
class TransferBreakdownCalculator {
  /// Calculate breakdown showing which expenses contribute to a transfer
  ///
  /// Analyzes all expenses to determine how the debt between fromUserId
  /// and toUserId accumulated. Returns proportional contributions that sum
  /// to the actual transfer amount.
  TransferBreakdown calculateBreakdown({
    required String fromUserId,
    required String toUserId,
    required Decimal transferAmount,
    required List<Expense> expenses,
  }) {
    final expenseBreakdowns = <ExpenseBreakdown>[];

    // First pass: calculate raw net contributions
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

      // Calculate net contribution to the transfer
      // Net = (what FROM paid - what FROM owes) - (what TO paid - what TO owes)
      // Positive net means FROM is owed money (increases debt to FROM, which means TO owes more)
      // Negative net means TO is owed money (decreases debt to FROM)

      // Actually, we want to track debt FROM -> TO
      // If FROM paid more than they owe, that reduces the debt
      // If FROM owes more than they paid, that increases the debt

      // Net contribution to FROM->TO debt:
      // = (what FROM owes - what FROM paid) - (what TO owes - what TO paid)
      // = what FROM owes to others - what TO owes to others + what TO paid - what FROM paid

      // Simpler: contribution = (fromOwes - fromPaid) - (toOwes - toPaid)
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

    // Calculate total positive contributions (expenses that increase the debt)
    final totalPositiveContributions = expenseBreakdowns
        .where((b) => b.netContribution > Decimal.zero)
        .fold(Decimal.zero, (sum, b) => sum + b.netContribution);

    // Scale contributions proportionally to match the actual transfer amount
    // This is necessary because the minimal transfer algorithm nets multiple debts
    // The raw contributions show expense-level debt changes, but the transfer
    // represents the netted/optimized payment
    final scaledBreakdowns = <ExpenseBreakdown>[];

    if (totalPositiveContributions > Decimal.zero) {
      final scaleFactor = (transferAmount / totalPositiveContributions).toDecimal();

      for (final breakdown in expenseBreakdowns) {
        scaledBreakdowns.add(ExpenseBreakdown(
          expense: breakdown.expense,
          fromPaid: breakdown.fromPaid,
          fromOwes: breakdown.fromOwes,
          toPaid: breakdown.toPaid,
          toOwes: breakdown.toOwes,
          netContribution: breakdown.netContribution * scaleFactor,
        ));
      }
    } else {
      // If no positive contributions, use raw values (edge case)
      scaledBreakdowns.addAll(expenseBreakdowns);
    }

    return TransferBreakdown(
      fromUserId: fromUserId,
      toUserId: toUserId,
      totalAmount: transferAmount,
      expenseBreakdowns: scaledBreakdowns,
    );
  }
}
