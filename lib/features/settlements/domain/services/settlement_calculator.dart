import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../../../expenses/domain/models/expense.dart';
import '../models/person_summary.dart';
import '../models/minimal_transfer.dart';
import '../../../../core/models/currency_code.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint(
    '[${DateTime.now().toIso8601String()}] [SettlementCalculator] $message',
  );
}

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
    _log(
      '🧮 calculatePersonSummaries() called with ${expenses.length} expenses',
    );
    final summaries = <String, _MutablePersonSummary>{};

    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      _log('\n📊 Processing expense ${i + 1}/${expenses.length}:');
      _log('  ID: ${expense.id}');
      _log('  Description: ${expense.description ?? "No description"}');
      _log('  Payer: ${expense.payerUserId}');
      _log('  Amount: ${expense.amount} ${expense.currency.code}');
      _log('  Split Type: ${expense.splitType}');
      _log('  Participants: ${expense.participants}');

      // Convert amount to base currency (for now, assume same currency)
      // TODO: Add FX conversion in Phase 5
      final amountInBase = expense.amount;

      // Update payer's total paid
      summaries.putIfAbsent(
        expense.payerUserId,
        () => _MutablePersonSummary(userId: expense.payerUserId),
      );
      summaries[expense.payerUserId]!.totalPaidBase += amountInBase;
      _log('  → ${expense.payerUserId} paid: $amountInBase');

      // Calculate and distribute shares
      final shares = expense.calculateShares();
      _log('  Calculated shares:');
      for (final entry in shares.entries) {
        final userId = entry.key;
        final shareAmount = entry.value;
        _log('    → $userId owes: $shareAmount');

        summaries.putIfAbsent(
          userId,
          () => _MutablePersonSummary(userId: userId),
        );
        summaries[userId]!.totalOwedBase += shareAmount;
      }
    }

    _log('\n💰 Raw Person Summaries (before adjustments):');
    summaries.forEach((userId, summary) {
      _log('  $userId:');
      _log('    Total Paid: ${summary.totalPaidBase}');
      _log('    Total Owed: ${summary.totalOwedBase}');
    });

    // Convert to immutable PersonSummary and calculate net
    final result = summaries.map((userId, mutable) {
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

    _log('\n✅ Final Person Summaries (with net balances):');
    result.forEach((userId, summary) {
      final status = summary.netBase > Decimal.zero
          ? 'Should RECEIVE ${summary.netBase.abs()}'
          : summary.netBase < Decimal.zero
          ? 'Should PAY ${summary.netBase.abs()}'
          : 'EVEN';
      _log('  $userId:');
      _log('    Total Paid: ${summary.totalPaidBase}');
      _log('    Total Owed: ${summary.totalOwedBase}');
      _log('    Net Balance: ${summary.netBase}');
      _log('    Status: $status');
    });

    return result;
  }

  /// Calculate pairwise netted transfers
  ///
  /// For each pair of people, calculates the direct debt between them
  /// by looking at all expenses they both participated in.
  /// Nets the debts (A→B minus B→A) to get the final transfer.
  ///
  /// This is simpler and more transparent than minimal transfers because
  /// each transfer directly corresponds to expenses between those two people.
  List<MinimalTransfer> calculatePairwiseNetTransfers({
    required String tripId,
    required List<Expense> expenses,
  }) {
    _log('\n🔄 calculatePairwiseNetTransfers() called');
    final transfers = <MinimalTransfer>[];
    final now = DateTime.now();

    // Build a map of pairwise debts: (fromUserId, toUserId) -> amount
    final pairwiseDebts = <String, Decimal>{};

    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      _log('\n📊 Processing expense ${i + 1}/${expenses.length}:');
      _log('  Description: ${expense.description ?? "No description"}');
      _log('  Payer: ${expense.payerUserId}');
      _log('  Amount: ${expense.amount} ${expense.currency.code}');

      final shares = expense.calculateShares();
      final payerId = expense.payerUserId;

      // For each participant who owes money
      for (final entry in shares.entries) {
        final participantId = entry.key;
        final shareAmount = entry.value;

        // Skip if payer is the same as participant (they don't owe themselves)
        if (participantId == payerId) continue;

        // Participant owes the payer
        final key = _pairKey(participantId, payerId);
        pairwiseDebts[key] = (pairwiseDebts[key] ?? Decimal.zero) + shareAmount;

        _log('  → $participantId owes $payerId: $shareAmount');
      }
    }

    _log('\n💰 Pairwise debts (before netting):');
    pairwiseDebts.forEach((key, amount) {
      _log('  $key: $amount');
    });

    // Now net the pairwise debts
    final nettedDebts = <String, Decimal>{};
    final processedPairs = <String>{};

    for (final entry in pairwiseDebts.entries) {
      final key = entry.key;
      if (processedPairs.contains(key)) continue;

      final parts = key.split('→');
      final userA = parts[0];
      final userB = parts[1];

      // Get debt in both directions
      final aOwesB = pairwiseDebts[_pairKey(userA, userB)] ?? Decimal.zero;
      final bOwesA = pairwiseDebts[_pairKey(userB, userA)] ?? Decimal.zero;

      // Calculate net debt
      final netDebt = aOwesB - bOwesA;

      _log('\n🔀 Netting debt between $userA and $userB:');
      _log('  $userA owes $userB: $aOwesB');
      _log('  $userB owes $userA: $bOwesA');
      _log('  Net: ${netDebt > Decimal.zero ? "$userA owes $userB $netDebt" : "$userB owes $userA ${netDebt.abs()}"}');

      if (netDebt.abs() >= Decimal.parse('0.01')) {
        // Create transfer for net debt
        if (netDebt > Decimal.zero) {
          // userA owes userB
          nettedDebts[_pairKey(userA, userB)] = netDebt;
        } else {
          // userB owes userA
          nettedDebts[_pairKey(userB, userA)] = netDebt.abs();
        }
      }

      // Mark both directions as processed
      processedPairs.add(_pairKey(userA, userB));
      processedPairs.add(_pairKey(userB, userA));
    }

    _log('\n✅ Netted debts:');
    nettedDebts.forEach((key, amount) {
      _log('  $key: $amount');
    });

    // Convert to MinimalTransfer objects
    for (final entry in nettedDebts.entries) {
      final parts = entry.key.split('→');
      final fromUserId = parts[0];
      final toUserId = parts[1];
      final amount = entry.value;

      transfers.add(
        MinimalTransfer(
          id: '', // Will be set by Firestore
          tripId: tripId,
          fromUserId: fromUserId,
          toUserId: toUserId,
          amountBase: amount,
          computedAt: now,
        ),
      );
    }

    _log('\n✅ Pairwise transfers calculation complete: ${transfers.length} transfers');
    return transfers;
  }

  /// Helper to create a consistent key for a pair of users
  String _pairKey(String fromUserId, String toUserId) {
    return '$fromUserId→$toUserId';
  }

  /// Calculate minimal transfers using greedy algorithm
  ///
  /// Input: Map of userId -> PersonSummary with net balances
  /// Output: List of transfers that settle all debts with minimum transactions
  ///
  /// DEPRECATED: Use calculatePairwiseNetTransfers() instead for simpler, more transparent transfers
  @Deprecated('Use calculatePairwiseNetTransfers() instead')
  List<MinimalTransfer> calculateMinimalTransfers({
    required String tripId,
    required Map<String, PersonSummary> personSummaries,
  }) {
    _log('\n🔄 calculateMinimalTransfers() called');
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

    _log('👥 Creditors (should receive money):');
    for (final c in creditors) {
      _log('  ${c.userId}: ${c.amount}');
    }

    _log('👥 Debtors (should pay money):');
    for (final d in debtors) {
      _log('  ${d.userId}: ${d.amount}');
    }

    // Sort by amount (largest first) for greedy algorithm
    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    _log('\n🔀 Starting greedy matching algorithm...');

    // Greedy matching: match largest creditor with largest debtor
    int transferCount = 0;
    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      final creditor = creditors.first;
      final debtor = debtors.first;

      // Determine transfer amount (minimum of what's owed and what's due)
      final transferAmount = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      transferCount++;
      _log('\n💸 Transfer #$transferCount:');
      _log('  ${debtor.userId} pays ${creditor.userId}');
      _log('  Amount: $transferAmount');
      _log('  (Creditor has ${creditor.amount}, Debtor owes ${debtor.amount})');

      // Create transfer
      transfers.add(
        MinimalTransfer(
          id: '', // Will be set by Firestore
          tripId: tripId,
          fromUserId: debtor.userId,
          toUserId: creditor.userId,
          amountBase: transferAmount,
          computedAt: now,
        ),
      );

      // Update balances
      creditor.amount -= transferAmount;
      debtor.amount -= transferAmount;

      _log(
        '  After transfer: Creditor remaining ${creditor.amount}, Debtor remaining ${debtor.amount}',
      );

      // Remove if settled (with small epsilon for floating point errors)
      if (creditor.amount < Decimal.parse('0.01')) {
        _log('  ✅ ${creditor.userId} fully settled (removed from creditors)');
        creditors.removeAt(0);
      }
      if (debtor.amount < Decimal.parse('0.01')) {
        _log('  ✅ ${debtor.userId} fully settled (removed from debtors)');
        debtors.removeAt(0);
      }
    }

    _log(
      '\n✅ Minimal transfers calculation complete: ${transfers.length} transfers',
    );
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
