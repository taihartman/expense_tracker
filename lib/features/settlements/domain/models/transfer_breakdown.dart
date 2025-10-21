import 'package:decimal/decimal.dart';
import '../../../expenses/domain/models/expense.dart';

/// Breakdown of how a single expense contributes to a transfer debt
class ExpenseBreakdown {
  /// The expense being analyzed
  final Expense expense;

  /// Amount the "from" person paid for this expense
  final Decimal fromPaid;

  /// Amount the "from" person owes for this expense
  final Decimal fromOwes;

  /// Amount the "to" person paid for this expense
  final Decimal toPaid;

  /// Amount the "to" person owes for this expense
  final Decimal toOwes;

  /// Net contribution to the transfer
  /// Positive = increases the debt from->to
  /// Negative = decreases the debt from->to (or reverses it)
  final Decimal netContribution;

  const ExpenseBreakdown({
    required this.expense,
    required this.fromPaid,
    required this.fromOwes,
    required this.toPaid,
    required this.toOwes,
    required this.netContribution,
  });

  /// Description of how this expense affects the transfer
  String get explanation {
    if (netContribution > Decimal.zero) {
      return 'Contributes ${netContribution.abs()} to transfer';
    } else if (netContribution < Decimal.zero) {
      return 'Reduces transfer by ${netContribution.abs()}';
    } else {
      return 'No net effect on transfer';
    }
  }
}

/// Complete breakdown of a transfer showing all contributing expenses
class TransferBreakdown {
  /// User ID of the person paying
  final String fromUserId;

  /// User ID of the person receiving
  final String toUserId;

  /// Total transfer amount
  final Decimal totalAmount;

  /// List of expenses that contributed to this transfer
  final List<ExpenseBreakdown> expenseBreakdowns;

  const TransferBreakdown({
    required this.fromUserId,
    required this.toUserId,
    required this.totalAmount,
    required this.expenseBreakdowns,
  });

  /// Get relevant expense breakdowns (those with non-zero net contribution)
  List<ExpenseBreakdown> get relevantBreakdowns {
    return expenseBreakdowns
        .where((b) => b.netContribution != Decimal.zero)
        .toList();
  }

  /// Sum of all positive contributions
  Decimal get totalPositiveContributions {
    return expenseBreakdowns
        .where((b) => b.netContribution > Decimal.zero)
        .fold(Decimal.zero, (sum, b) => sum + b.netContribution);
  }

  /// Sum of all negative contributions (absolute value)
  Decimal get totalNegativeContributions {
    return expenseBreakdowns
        .where((b) => b.netContribution < Decimal.zero)
        .fold(Decimal.zero, (sum, b) => sum + b.netContribution.abs());
  }
}
