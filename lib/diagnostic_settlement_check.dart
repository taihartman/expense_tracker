import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'features/expenses/data/models/expense_model.dart';
import 'features/settlements/domain/services/settlement_calculator.dart';
import 'core/models/currency_code.dart';

/// Diagnostic script to analyze settlement calculations
/// Run with: flutter run -d chrome -t lib/diagnostic_settlement_check.dart

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('=== SETTLEMENT DIAGNOSTIC TOOL ===\n');

  try {
    // Get Firestore instance
    final firestore = FirebaseFirestore.instance;

    // Get all trips
    debugPrint('Fetching trips...');
    final tripsSnapshot = await firestore.collection('trips').get();

    if (tripsSnapshot.docs.isEmpty) {
      debugPrint('No trips found in database.');
      return;
    }

    // Use the first trip (or let user specify)
    final tripDoc = tripsSnapshot.docs.first;
    final tripId = tripDoc.id;
    final tripData = tripDoc.data();
    final tripName = tripData['name'] ?? 'Unknown Trip';
    final baseCurrency = CurrencyCode.values.firstWhere(
      (c) => c.code == tripData['baseCurrency'],
      orElse: () => CurrencyCode.usd,
    );

    debugPrint('Analyzing trip: $tripName (ID: $tripId)');
    debugPrint('Base currency: ${baseCurrency.code}\n');

    // Get all expenses for this trip
    debugPrint('Fetching expenses for trip...');
    final expensesSnapshot = await firestore
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .get();

    if (expensesSnapshot.docs.isEmpty) {
      debugPrint('No expenses found for this trip.');
      return;
    }

    final expenses = expensesSnapshot.docs
        .map((doc) => ExpenseModel.fromFirestore(doc))
        .toList();

    debugPrint('Found ${expenses.length} expenses\n');
    debugPrint('=== ALL EXPENSES ===');
    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      debugPrint('\nExpense ${i + 1}:');
      debugPrint('  ID: ${expense.id}');
      debugPrint('  Date: ${expense.date.toString().split(' ')[0]}');
      debugPrint('  Payer: ${expense.payerUserId}');
      debugPrint('  Amount: ${expense.amount} ${expense.currency.code}');
      debugPrint('  Description: ${expense.description ?? 'No description'}');
      debugPrint('  Split Type: ${expense.splitType}');
      debugPrint('  Participants:');
      expense.participants.forEach((userId, weight) {
        debugPrint('    - $userId: weight=$weight');
      });

      // Calculate and show shares
      final shares = expense.calculateShares();
      debugPrint('  Calculated Shares:');
      shares.forEach((userId, share) {
        debugPrint('    - $userId owes: $share ${expense.currency.code}');
      });
    }

    // Now calculate settlements
    debugPrint('\n=== CALCULATING SETTLEMENTS ===\n');

    final calculator = SettlementCalculator();
    final personSummaries = calculator.calculatePersonSummaries(
      expenses: expenses,
      baseCurrency: baseCurrency,
    );

    debugPrint('Person Summaries:');
    personSummaries.forEach((userId, summary) {
      debugPrint('\n$userId:');
      debugPrint('  Total Paid: ${summary.totalPaidBase}');
      debugPrint('  Total Owed: ${summary.totalOwedBase}');
      debugPrint('  Net Balance: ${summary.netBase}');
      if (summary.netBase > Decimal.zero) {
        debugPrint('  Status: Should receive ${summary.netBase}');
      } else if (summary.netBase < Decimal.zero) {
        debugPrint('  Status: Should pay ${summary.netBase.abs()}');
      } else {
        debugPrint('  Status: Even');
      }
    });

    // Calculate pairwise netted transfers
    debugPrint('\n=== PAIRWISE NETTED TRANSFERS ===\n');
    final transfers = calculator.calculatePairwiseNetTransfers(
      tripId: tripId,
      expenses: expenses,
    );

    debugPrint('Found ${transfers.length} transfers needed:');
    for (int i = 0; i < transfers.length; i++) {
      final transfer = transfers[i];
      debugPrint('\nTransfer ${i + 1}:');
      debugPrint('  ${transfer.fromUserId} pays ${transfer.toUserId}');
      debugPrint('  Amount: ${transfer.amountBase} ${baseCurrency.code}');
    }

    // Find Izzy -> Ethan transfer specifically
    debugPrint('\n=== IZZY -> ETHAN ANALYSIS ===\n');
    final izzyEthanTransfer = transfers.firstWhere(
      (t) => t.fromUserId == 'izzy' && t.toUserId == 'ethan',
      orElse: () => transfers.firstWhere(
        (t) =>
            t.fromUserId.toLowerCase() == 'izzy' &&
            t.toUserId.toLowerCase() == 'ethan',
        orElse: () => transfers.first, // Return first if not found
      ),
    );

    if (izzyEthanTransfer.fromUserId.toLowerCase() == 'izzy' &&
        izzyEthanTransfer.toUserId.toLowerCase() == 'ethan') {
      debugPrint('Found Izzy -> Ethan transfer:');
      debugPrint('Amount: ${izzyEthanTransfer.amountBase}');
    } else {
      debugPrint(
        'No Izzy -> Ethan transfer found. Showing all transfers involving Izzy or Ethan:',
      );
      final relevantTransfers = transfers.where(
        (t) =>
            t.fromUserId.toLowerCase() == 'izzy' ||
            t.toUserId.toLowerCase() == 'izzy' ||
            t.fromUserId.toLowerCase() == 'ethan' ||
            t.toUserId.toLowerCase() == 'ethan',
      );

      for (final t in relevantTransfers) {
        debugPrint('  ${t.fromUserId} -> ${t.toUserId}: ${t.amountBase}');
      }
    }

    // Detailed breakdown for Izzy
    debugPrint('\n=== IZZY DETAILED BREAKDOWN ===\n');
    final izzyExpenses = expenses
        .where(
          (e) =>
              e.payerUserId.toLowerCase() == 'izzy' ||
              e.participants.keys.any((k) => k.toLowerCase() == 'izzy'),
        )
        .toList();

    debugPrint('Expenses involving Izzy: ${izzyExpenses.length}');
    Decimal izzyPaid = Decimal.zero;
    Decimal izzyOwes = Decimal.zero;

    for (final expense in izzyExpenses) {
      if (expense.payerUserId.toLowerCase() == 'izzy') {
        izzyPaid += expense.amount;
        debugPrint('\nPaid: ${expense.amount} for "${expense.description}"');
      }

      final shares = expense.calculateShares();
      for (final entry in shares.entries) {
        if (entry.key.toLowerCase() == 'izzy') {
          izzyOwes += entry.value;
          debugPrint(
            'Owes: ${entry.value} for "${expense.description}" (paid by ${expense.payerUserId})',
          );
        }
      }
    }

    debugPrint('\nIzzy Summary:');
    debugPrint('  Total Paid: $izzyPaid');
    debugPrint('  Total Owes: $izzyOwes');
    debugPrint('  Net: ${izzyPaid - izzyOwes}');

    // Detailed breakdown for Ethan
    debugPrint('\n=== ETHAN DETAILED BREAKDOWN ===\n');
    final ethanExpenses = expenses
        .where(
          (e) =>
              e.payerUserId.toLowerCase() == 'ethan' ||
              e.participants.keys.any((k) => k.toLowerCase() == 'ethan'),
        )
        .toList();

    debugPrint('Expenses involving Ethan: ${ethanExpenses.length}');
    Decimal ethanPaid = Decimal.zero;
    Decimal ethanOwes = Decimal.zero;

    for (final expense in ethanExpenses) {
      if (expense.payerUserId.toLowerCase() == 'ethan') {
        ethanPaid += expense.amount;
        debugPrint('\nPaid: ${expense.amount} for "${expense.description}"');
      }

      final shares = expense.calculateShares();
      for (final entry in shares.entries) {
        if (entry.key.toLowerCase() == 'ethan') {
          ethanOwes += entry.value;
          debugPrint(
            'Owes: ${entry.value} for "${expense.description}" (paid by ${expense.payerUserId})',
          );
        }
      }
    }

    debugPrint('\nEthan Summary:');
    debugPrint('  Total Paid: $ethanPaid');
    debugPrint('  Total Owes: $ethanOwes');
    debugPrint('  Net: ${ethanPaid - ethanOwes}');

    // Validation
    debugPrint('\n=== VALIDATION ===\n');
    final isValid = calculator.validateBalances(personSummaries);
    debugPrint('Balance conservation valid: $isValid');

    if (!isValid) {
      debugPrint('WARNING: Sum of net balances does not equal zero!');
      final sum = personSummaries.values
          .map((p) => p.netBase)
          .fold(Decimal.zero, (a, b) => a + b);
      debugPrint('Sum of net balances: $sum');
    }

    debugPrint('\n=== END OF DIAGNOSTIC ===');
  } catch (e, stackTrace) {
    debugPrint('ERROR: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
