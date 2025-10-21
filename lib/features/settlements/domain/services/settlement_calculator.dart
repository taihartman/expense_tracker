import 'package:decimal/decimal.dart';
import '../../../expenses/domain/models/expense.dart';
import '../models/person_summary.dart';
import '../models/minimal_transfer.dart';
import '../../../../core/models/currency_code.dart';

/// Service for calculating settlements from expenses
/// 
/// Implements pairwise debt netting and minimal transfer algorithms
class SettlementCalculator {
  /// Calculate person summaries from expenses
  /// 
  /// Returns map of userId -> PersonSummary with totals in base currency
  Map<String, PersonSummary> calculatePersonSummaries({
    required List<Expense> expenses,
    required CurrencyCode baseCurrency,
  }) {
    final summaries = <String, _MutablePersonSummary>{};

    for (final expense in expenses) {
      // Convert amount to base currency (for now, assume same currency)
      // TODO: Add FX conversion in Phase 5
      final amountInBase = expense.amount;

      // Update payer's total paid
      summaries.putIfAbsent(
        expense.payerUserId,
        () => _MutablePersonSummary(userId: expense.payerUserId),
      );
      summaries[expense.payerUserId]!.totalPaidBase += amountInBase;

      // Calculate and distribute shares
      final shares = expense.calculateShares();
      for (final entry in shares.entries) {
        final userId = entry.key;
        final shareAmount = entry.value;

        summaries.putIfAbsent(
          userId,
          () => _MutablePersonSummary(userId: userId),
        );
        summaries[userId]!.totalOwedBase += shareAmount;
      }
    }

    // Convert to immutable PersonSummary and calculate net
    return summaries.map((userId, mutable) {
      final netBase = mutable.totalPaidBase - mutable.totalOwedBase;
      return MapEntry(
        userId,
        PersonSummary(
          userId: userId,
          totalPaidBase: mutable.totalPaidBase,
          totalOwedBase: mutable.totalOwedBase,
          netBase: netBase,
        ),
      );
    });
  }

  /// Calculate minimal transfers using greedy algorithm
  /// 
  /// Input: Map of userId -> PersonSummary with net balances
  /// Output: List of transfers that settle all debts with minimum transactions
  List<MinimalTransfer> calculateMinimalTransfers({
    required String tripId,
    required Map<String, PersonSummary> personSummaries,
  }) {
    final transfers = <MinimalTransfer>[];
    final now = DateTime.now();

    // Separate into creditors (net > 0) and debtors (net < 0)
    final creditors = personSummaries.values
        .where((p) => p.netBase > Decimal.zero)
        .map((p) => _Balance(userId: p.userId, amount: p.netBase))
        .toList();

    final debtors = personSummaries.values
        .where((p) => p.netBase < Decimal.zero)
        .map((p) => _Balance(userId: p.userId, amount: p.netBase.abs()))
        .toList();

    // Sort by amount (largest first) for greedy algorithm
    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    // Greedy matching: match largest creditor with largest debtor
    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      final creditor = creditors.first;
      final debtor = debtors.first;

      // Determine transfer amount (minimum of what's owed and what's due)
      final transferAmount = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      // Create transfer
      transfers.add(MinimalTransfer(
        id: '', // Will be set by Firestore
        tripId: tripId,
        fromUserId: debtor.userId,
        toUserId: creditor.userId,
        amountBase: transferAmount,
        computedAt: now,
      ));

      // Update balances
      creditor.amount -= transferAmount;
      debtor.amount -= transferAmount;

      // Remove if settled (with small epsilon for floating point errors)
      if (creditor.amount < Decimal.parse('0.01')) {
        creditors.removeAt(0);
      }
      if (debtor.amount < Decimal.parse('0.01')) {
        debtors.removeAt(0);
      }
    }

    return transfers;
  }

  /// Validate that sum of all net balances equals zero
  /// 
  /// Returns true if conservation of money holds
  bool validateBalances(Map<String, PersonSummary> personSummaries) {
    final sum = personSummaries.values
        .map((p) => p.netBase)
        .fold(Decimal.zero, (a, b) => a + b);

    // Allow small epsilon for rounding errors
    return sum.abs() < Decimal.parse('0.01');
  }
}

/// Mutable version of PersonSummary for calculation
class _MutablePersonSummary {
  final String userId;
  Decimal totalPaidBase;
  Decimal totalOwedBase;

  _MutablePersonSummary({required this.userId})
      : totalPaidBase = Decimal.zero,
        totalOwedBase = Decimal.zero;
}

/// Helper class for tracking balances during transfer calculation
class _Balance {
  final String userId;
  Decimal amount;

  _Balance({required this.userId, required this.amount});
}
