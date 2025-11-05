import 'package:decimal/decimal.dart';
import '../models/settlement_summary.dart';
import '../models/minimal_transfer.dart';
import '../models/person_summary.dart';

/// Result of settlement validation
class ValidationResult {
  final bool isValid;
  final List<String> issues;

  const ValidationResult({
    required this.isValid,
    required this.issues,
  });

  /// Creates a successful validation result
  factory ValidationResult.success() {
    return const ValidationResult(isValid: true, issues: []);
  }

  /// Creates a failed validation result with issues
  factory ValidationResult.failure(List<String> issues) {
    return ValidationResult(isValid: false, issues: issues);
  }

  @override
  String toString() {
    if (isValid) {
      return 'ValidationResult: VALID';
    }
    return 'ValidationResult: INVALID\n  Issues:\n${issues.map((i) => '    - $i').join('\n')}';
  }
}

/// Validates settlement calculations for mathematical correctness
///
/// Ensures:
/// 1. Conservation of money (sum of balances = 0)
/// 2. No duplicate transfers
/// 3. All participants exist in person summaries
/// 4. Transfer amounts match person balances
class SettlementValidator {
  /// Epsilon for floating point comparisons
  static final Decimal _epsilon = Decimal.parse('0.02');
  static final Decimal _balanceEpsilon = Decimal.parse('1.00');

  /// Validates that settlement is mathematically sound
  ///
  /// Performs comprehensive validation including:
  /// - Conservation of money
  /// - Transfer consistency
  /// - No duplicates
  /// - Balance matching
  ValidationResult validate(
    SettlementSummary summary,
    List<MinimalTransfer> pendingTransfers,
  ) {
    final issues = <String>[];

    // 1. Conservation of money (sum of all net balances = 0)
    issues.addAll(_validateConservationOfMoney(summary.personSummaries));

    // 2. Each transfer has valid payer/receiver
    issues.addAll(_validateTransferParticipants(
      summary.personSummaries,
      pendingTransfers,
    ));

    // 3. No duplicate transfers
    issues.addAll(_validateNoDuplicateTransfers(pendingTransfers));

    // 4. Transfer amounts match person balances
    issues.addAll(_validateTransferBalances(
      summary.personSummaries,
      pendingTransfers,
    ));

    // 5. No negative amounts
    issues.addAll(_validateNoNegativeAmounts(pendingTransfers));

    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }

  /// Validates conservation of money: sum of all balances must equal zero
  List<String> _validateConservationOfMoney(
    Map<String, PersonSummary> personSummaries,
  ) {
    final issues = <String>[];

    final totalBalance = personSummaries.values
        .map((p) => p.netBase)
        .fold(Decimal.zero, (a, b) => a + b);

    if (totalBalance.abs() > _epsilon) {
      issues.add(
        'Conservation of money violated: sum of balances = $totalBalance '
        '(should be ≈0, tolerance: ±$_epsilon)',
      );
    }

    return issues;
  }

  /// Validates that all transfer participants exist in person summaries
  List<String> _validateTransferParticipants(
    Map<String, PersonSummary> personSummaries,
    List<MinimalTransfer> transfers,
  ) {
    final issues = <String>[];

    for (final transfer in transfers) {
      if (!personSummaries.containsKey(transfer.fromUserId)) {
        issues.add(
          'Transfer ${transfer.id} has unknown payer: ${transfer.fromUserId}',
        );
      }

      if (!personSummaries.containsKey(transfer.toUserId)) {
        issues.add(
          'Transfer ${transfer.id} has unknown receiver: ${transfer.toUserId}',
        );
      }

      // Validate fromUserId != toUserId
      if (transfer.fromUserId == transfer.toUserId) {
        issues.add(
          'Transfer ${transfer.id} has same payer and receiver: ${transfer.fromUserId}',
        );
      }
    }

    return issues;
  }

  /// Validates no duplicate transfers exist (same fromUserId-toUserId pair)
  List<String> _validateNoDuplicateTransfers(
    List<MinimalTransfer> transfers,
  ) {
    final issues = <String>[];
    final transferKeys = <String>[];
    final seenKeys = <String, List<String>>{};

    for (final transfer in transfers) {
      final key = '${transfer.fromUserId}-${transfer.toUserId}';
      transferKeys.add(key);

      seenKeys.putIfAbsent(key, () => []).add(transfer.id);
    }

    // Check for duplicates
    for (final entry in seenKeys.entries) {
      if (entry.value.length > 1) {
        issues.add(
          'Duplicate transfers detected for pair ${entry.key}: '
          '${entry.value.length} transfers found (IDs: ${entry.value.join(', ')})',
        );
      }
    }

    return issues;
  }

  /// Validates that transfer amounts match person net balances
  ///
  /// For each person:
  /// incoming transfers - outgoing transfers ≈ net balance
  List<String> _validateTransferBalances(
    Map<String, PersonSummary> personSummaries,
    List<MinimalTransfer> transfers,
  ) {
    final issues = <String>[];

    for (final entry in personSummaries.entries) {
      final userId = entry.key;
      final summary = entry.value;

      // Calculate total outgoing (what this person pays)
      final outgoing = transfers
          .where((t) => t.fromUserId == userId)
          .map((t) => t.amountBase)
          .fold(Decimal.zero, (a, b) => a + b);

      // Calculate total incoming (what this person receives)
      final incoming = transfers
          .where((t) => t.toUserId == userId)
          .map((t) => t.amountBase)
          .fold(Decimal.zero, (a, b) => a + b);

      // Net from transfers: incoming - outgoing
      final netFromTransfers = incoming - outgoing;

      // Expected net from summary
      final expectedNet = summary.netBase;

      // Check if they match (within tolerance)
      final difference = (netFromTransfers - expectedNet).abs();

      if (difference > _balanceEpsilon) {
        issues.add(
          'Balance mismatch for $userId: '
          'transfers show net = $netFromTransfers, '
          'but person summary shows net = $expectedNet '
          '(difference: $difference, tolerance: ±$_balanceEpsilon)',
        );
      }
    }

    return issues;
  }

  /// Validates no transfers have negative amounts
  List<String> _validateNoNegativeAmounts(List<MinimalTransfer> transfers) {
    final issues = <String>[];

    for (final transfer in transfers) {
      if (transfer.amountBase < Decimal.zero) {
        issues.add(
          'Transfer ${transfer.id} has negative amount: ${transfer.amountBase}',
        );
      }

      if (transfer.amountBase == Decimal.zero) {
        issues.add(
          'Transfer ${transfer.id} has zero amount (should be filtered out)',
        );
      }
    }

    return issues;
  }

  /// Quick validation: just check conservation of money
  ///
  /// Useful for fast checks without full validation
  bool quickValidate(Map<String, PersonSummary> personSummaries) {
    final totalBalance = personSummaries.values
        .map((p) => p.netBase)
        .fold(Decimal.zero, (a, b) => a + b);

    return totalBalance.abs() < _epsilon;
  }
}
