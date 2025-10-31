import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../categories/domain/models/category.dart' as cat;
import '../models/person_summary.dart';
import '../models/minimal_transfer.dart';
import '../models/category_spending.dart';
import '../../../../core/models/currency_code.dart';

/// Helper function to log with timestamps (only in debug mode)
void _log(String message) {
  if (kDebugMode) {
    debugPrint(
      '[${DateTime.now().toIso8601String()}] [SettlementCalculator] $message',
    );
  }
}

/// Service for calculating settlements from expenses
///
/// Implements pairwise debt netting and minimal transfer algorithms
class SettlementCalculator {
  /// Calculate both person summaries AND category spending in a single pass
  ///
  /// This is an optimized version that processes expenses only once
  /// instead of iterating twice (once for summaries, once for category spending).
  ({
    Map<String, PersonSummary> personSummaries,
    Map<String, PersonCategorySpending>? categorySpending,
  })
  calculateSettlementData({
    required List<Expense> expenses,
    required CurrencyCode baseCurrency,
    List<cat.Category>? categories,
  }) {
    _log(
      '🧮 calculateSettlementData() called with ${expenses.length} expenses (single-pass optimization)',
    );

    final summaries = <String, _MutablePersonSummary>{};
    final userCategorySpending = <String, Map<String, Decimal>>{};

    // Build category lookup map if categories provided
    final categoryMap = <String, cat.Category>{};
    if (categories != null) {
      for (final category in categories) {
        categoryMap[category.id] = category;
      }
    }

    // SINGLE PASS through all expenses
    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      _log('\n📊 Processing expense ${i + 1}/${expenses.length}:');
      _log('  ID: ${expense.id}');
      _log('  Description: ${expense.description ?? "No description"}');
      _log('  Payer: ${expense.payerUserId}');
      _log('  Amount: ${expense.amount} ${expense.currency.code}');

      // Convert amount to base currency (TODO: FX conversion)
      final amountInBase = expense.amount;

      // Update payer's total paid
      summaries.putIfAbsent(
        expense.payerUserId,
        () => _MutablePersonSummary(userId: expense.payerUserId),
      );
      summaries[expense.payerUserId]!.totalPaidBase += amountInBase;
      _log('  → ${expense.payerUserId} paid: $amountInBase');

      // Calculate shares
      final Map<String, Decimal> shares;
      if (expense.participantAmounts != null &&
          expense.participantAmounts!.isNotEmpty) {
        shares = expense.participantAmounts!;
        _log('  Using pre-calculated participantAmounts (itemized):');
      } else {
        shares = expense.calculateShares();
        _log('  Calculated shares (equal/weighted):');
      }

      final categoryId = expense.categoryId ?? 'uncategorized';

      // Process each participant's share
      for (final entry in shares.entries) {
        final userId = entry.key;
        final shareAmount = entry.value;
        _log('    → $userId owes: $shareAmount');

        // Update person summary
        summaries.putIfAbsent(
          userId,
          () => _MutablePersonSummary(userId: userId),
        );
        summaries[userId]!.totalOwedBase += shareAmount;

        // Update category spending (if categories provided)
        if (categories != null) {
          userCategorySpending.putIfAbsent(userId, () => <String, Decimal>{});
          userCategorySpending[userId]!.update(
            categoryId,
            (current) => current + shareAmount,
            ifAbsent: () => shareAmount,
          );
        }
      }
    }

    _log('\n💰 Raw Person Summaries (before adjustments):');
    summaries.forEach((userId, summary) {
      _log('  $userId:');
      _log('    Total Paid: ${summary.totalPaidBase}');
      _log('    Total Owed: ${summary.totalOwedBase}');
    });

    // Convert to immutable PersonSummary and calculate net
    final personSummaries = summaries.map((userId, mutable) {
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
    personSummaries.forEach((userId, summary) {
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

    // Build category spending if categories were provided
    Map<String, PersonCategorySpending>? categorySpending;
    if (categories != null && userCategorySpending.isNotEmpty) {
      _log('\n💰 Building PersonCategorySpending results:');
      categorySpending = <String, PersonCategorySpending>{};

      for (final userId in summaries.keys) {
        final summary = personSummaries[userId]!;
        final userCategories = userCategorySpending[userId] ?? {};

        // Build category breakdown list
        final categoryBreakdown = <CategorySpending>[];
        for (final categoryEntry in userCategories.entries) {
          final categoryId = categoryEntry.key;
          final amount = categoryEntry.value;

          // Get category metadata
          final category = categoryMap[categoryId];
          final categoryName =
              category?.name ??
              (categoryId == 'uncategorized' ? 'Uncategorized' : categoryId);
          final color = category?.color;
          final icon = category?.icon;

          categoryBreakdown.add(
            CategorySpending(
              categoryId: categoryId,
              categoryName: categoryName,
              amount: amount,
              color: color,
              icon: icon,
            ),
          );

          _log('  $userId - $categoryName: $amount');
        }

        // Sort by amount descending
        categoryBreakdown.sort((a, b) => b.amount.compareTo(a.amount));

        categorySpending[userId] = PersonCategorySpending(
          userId: userId,
          totalPaidBase: summary.totalPaidBase,
          totalOwedBase: summary.totalOwedBase,
          netBase: summary.netBase,
          categoryBreakdown: categoryBreakdown,
        );
      }

      _log(
        '\n✅ Category spending calculated for ${categorySpending.length} users',
      );
    }

    _log('\n✅ Single-pass calculation complete');
    return (
      personSummaries: personSummaries,
      categorySpending: categorySpending,
    );
  }

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
      // For itemized expenses, use pre-calculated participantAmounts
      // For equal/weighted expenses, calculate shares
      final Map<String, Decimal> shares;
      if (expense.participantAmounts != null &&
          expense.participantAmounts!.isNotEmpty) {
        shares = expense.participantAmounts!;
        _log('  Using pre-calculated participantAmounts (itemized):');
      } else {
        shares = expense.calculateShares();
        _log('  Calculated shares (equal/weighted):');
      }

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

  /// Calculate per-person category spending breakdown
  ///
  /// Returns map of userId -> PersonCategorySpending with category breakdown
  /// Requires category list to attach names/colors to spending
  Map<String, PersonCategorySpending> calculatePersonCategorySpending({
    required List<Expense> expenses,
    required List<cat.Category> categories,
    required CurrencyCode baseCurrency,
  }) {
    _log(
      '\n📊 calculatePersonCategorySpending() called with ${expenses.length} expenses, ${categories.length} categories',
    );

    // Build category lookup map for quick access
    final categoryMap = <String, cat.Category>{};
    for (final category in categories) {
      categoryMap[category.id] = category;
    }

    // Track spending: userId -> categoryId -> amount
    final userCategorySpending = <String, Map<String, Decimal>>{};

    // Track totals: userId -> (totalPaid, totalOwed)
    final userTotals = <String, _MutablePersonSummary>{};

    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      _log('\n📊 Processing expense ${i + 1}/${expenses.length}:');
      _log('  Description: ${expense.description ?? "No description"}');
      _log('  Category: ${expense.categoryId ?? "Uncategorized"}');
      _log('  Amount: ${expense.amount} ${expense.currency.code}');

      // Convert amount to base currency (TODO: FX conversion in Phase 5)
      final amountInBase = expense.amount;

      // Update payer's total paid
      userTotals.putIfAbsent(
        expense.payerUserId,
        () => _MutablePersonSummary(userId: expense.payerUserId),
      );
      userTotals[expense.payerUserId]!.totalPaidBase += amountInBase;

      // Calculate shares for participants
      final Map<String, Decimal> shares;
      if (expense.participantAmounts != null &&
          expense.participantAmounts!.isNotEmpty) {
        shares = expense.participantAmounts!;
        _log('  Using pre-calculated participantAmounts (itemized)');
      } else {
        shares = expense.calculateShares();
        _log('  Calculated shares (equal/weighted)');
      }

      // Distribute spending to categories per user
      final categoryId = expense.categoryId ?? 'uncategorized';

      for (final entry in shares.entries) {
        final userId = entry.key;
        final shareAmount = entry.value;
        _log('    → $userId owes: $shareAmount for category: $categoryId');

        // Update total owed
        userTotals.putIfAbsent(
          userId,
          () => _MutablePersonSummary(userId: userId),
        );
        userTotals[userId]!.totalOwedBase += shareAmount;

        // Update category spending
        userCategorySpending.putIfAbsent(userId, () => <String, Decimal>{});
        userCategorySpending[userId]!.update(
          categoryId,
          (current) => current + shareAmount,
          ifAbsent: () => shareAmount,
        );
      }
    }

    _log('\n💰 Building PersonCategorySpending results:');

    // Build final PersonCategorySpending objects
    final result = <String, PersonCategorySpending>{};

    for (final entry in userTotals.entries) {
      final userId = entry.key;
      final totals = entry.value;
      final netBase = totals.totalPaidBase - totals.totalOwedBase;

      // Build category breakdown list
      final categoryBreakdown = <CategorySpending>[];
      final userCategories = userCategorySpending[userId] ?? {};

      for (final categoryEntry in userCategories.entries) {
        final categoryId = categoryEntry.key;
        final amount = categoryEntry.value;

        // Get category metadata
        final category = categoryMap[categoryId];
        final categoryName =
            category?.name ??
            (categoryId == 'uncategorized' ? 'Uncategorized' : categoryId);
        final color = category?.color;
        final icon = category?.icon;

        categoryBreakdown.add(
          CategorySpending(
            categoryId: categoryId,
            categoryName: categoryName,
            amount: amount,
            color: color,
            icon: icon,
          ),
        );

        _log('  $userId - $categoryName: $amount');
      }

      // Sort by amount descending
      categoryBreakdown.sort((a, b) => b.amount.compareTo(a.amount));

      result[userId] = PersonCategorySpending(
        userId: userId,
        totalPaidBase: totals.totalPaidBase,
        totalOwedBase: totals.totalOwedBase,
        netBase: netBase,
        categoryBreakdown: categoryBreakdown,
      );
    }

    _log(
      '\n✅ Category spending calculation complete for ${result.length} users',
    );
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

      // For itemized expenses, use pre-calculated participantAmounts
      // For equal/weighted expenses, calculate shares
      final Map<String, Decimal> shares;
      if (expense.participantAmounts != null &&
          expense.participantAmounts!.isNotEmpty) {
        shares = expense.participantAmounts!;
        _log('  Using pre-calculated participantAmounts (itemized)');
      } else {
        shares = expense.calculateShares();
        _log('  Calculated shares (equal/weighted)');
      }

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
      _log(
        '  Net: ${netDebt > Decimal.zero ? "$userA owes $userB $netDebt" : "$userB owes $userA ${netDebt.abs()}"}',
      );

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

    _log(
      '\n✅ Pairwise transfers calculation complete: ${transfers.length} transfers',
    );
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
