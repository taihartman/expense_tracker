import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_config.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/remainder_distribution_mode.dart';
import 'package:expense_tracker/features/expenses/domain/services/rounding_service.dart';

void main() {
  group('RoundingService', () {
    late RoundingService service;

    setUp(() {
      service = RoundingService();
    });

    group('roundAmounts - largestShare distribution', () {
      test('distributes remainder to participant with largest unrounded amount', () {
        // Scenario: $10.00 split among 3 people
        // Each gets $3.333... → $3.33, $3.33, $3.33 = $9.99
        // Remainder: $0.01 goes to largest share
        final amounts = {
          'alice': Decimal.parse('3.333333'),
          'bob': Decimal.parse('3.333333'),
          'charlie': Decimal.parse('3.333333'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // Total should be preserved
        final total = result.values.fold(
          Decimal.zero,
          (sum, amount) => sum + amount,
        );
        expect(total, Decimal.parse('10.00'));

        // One person should get $3.34, two get $3.33
        final values = result.values.toList()..sort();
        expect(values[0], Decimal.parse('3.33'));
        expect(values[1], Decimal.parse('3.33'));
        expect(values[2], Decimal.parse('3.34'));
      });

      test('handles multiple cents remainder with different original amounts', () {
        // Scenario: Different shares, multiple cent remainder
        final amounts = {
          'alice': Decimal.parse('15.556'), // Largest
          'bob': Decimal.parse('10.224'),
          'charlie': Decimal.parse('5.113'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // Original total: $30.893
        // Rounded individually: $15.56 + $10.22 + $5.11 = $30.89
        // Remainder: $0.003 (rounds to $0.00, no distribution needed)
        final total = result.values.fold(
          Decimal.zero,
          (sum, amount) => sum + amount,
        );

        // Should preserve original total when rounded
        expect(total, Decimal.parse('30.89'));

        // Alice (largest) should get any remainder
        expect(result['alice'], Decimal.parse('15.56'));
      });

      test('handles VND currency (zero decimal places)', () {
        // Scenario: 10,001 VND split among 3 people
        // Each gets 3,333.666... → 3,334, 3,334, 3,333 = 10,001
        final amounts = {
          'alice': Decimal.parse('3333.666666'),
          'bob': Decimal.parse('3333.666666'),
          'charlie': Decimal.parse('3333.666666'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('1'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'VND',
        );

        final total = result.values.fold(
          Decimal.zero,
          (sum, amount) => sum + amount,
        );
        expect(total, Decimal.parse('10001'));

        // All amounts should be whole numbers
        result.values.forEach((amount) {
          expect(amount.scale, 0);
        });
      });
    });

    group('roundAmounts - payer distribution', () {
      test('distributes remainder to designated payer', () {
        final amounts = {
          'alice': Decimal.parse('3.333333'),
          'bob': Decimal.parse('3.333333'),
          'charlie': Decimal.parse('3.333333'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.payer,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
          payerId: 'bob',
        );

        // Bob (payer) should get the remainder
        expect(result['bob'], Decimal.parse('3.34'));
        expect(result['alice'], Decimal.parse('3.33'));
        expect(result['charlie'], Decimal.parse('3.33'));
      });

      test('throws error if payer not specified with payer distribution mode', () {
        final amounts = {
          'alice': Decimal.parse('3.333333'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.payer,
        );

        expect(
          () => service.roundAmounts(
            amounts: amounts,
            config: config,
            currencyCode: 'USD',
            // Missing payerId
          ),
          throwsArgumentError,
        );
      });

      test('throws error if payer not in amounts map', () {
        final amounts = {
          'alice': Decimal.parse('3.333333'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.payer,
        );

        expect(
          () => service.roundAmounts(
            amounts: amounts,
            config: config,
            currencyCode: 'USD',
            payerId: 'bob', // Not in amounts
          ),
          throwsArgumentError,
        );
      });
    });

    group('roundAmounts - firstListed distribution', () {
      test('distributes remainder to first participant in map', () {
        // Note: In Dart, LinkedHashMap preserves insertion order
        final amounts = {
          'charlie': Decimal.parse('3.333333'),
          'alice': Decimal.parse('3.333333'),
          'bob': Decimal.parse('3.333333'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.firstListed,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // Charlie (first in insertion order) should get remainder
        expect(result['charlie'], Decimal.parse('3.34'));
        expect(result['alice'], Decimal.parse('3.33'));
        expect(result['bob'], Decimal.parse('3.33'));
      });

      test('handles multiple cent remainder for first participant', () {
        final amounts = {
          'alice': Decimal.parse('5.555'),
          'bob': Decimal.parse('5.555'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.firstListed,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // $11.11 total, alice gets remainder
        expect(result['alice'], Decimal.parse('5.56'));
        expect(result['bob'], Decimal.parse('5.55'));
      });
    });

    group('roundAmounts - random distribution', () {
      test('distributes remainder randomly but preserves total', () {
        final amounts = {
          'alice': Decimal.parse('3.333333'),
          'bob': Decimal.parse('3.333333'),
          'charlie': Decimal.parse('3.333333'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.random,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // Total must be preserved
        final total = result.values.fold(
          Decimal.zero,
          (sum, amount) => sum + amount,
        );
        expect(total, Decimal.parse('10.00'));

        // One person gets $3.34, others get $3.33 (but we don't know who)
        final values = result.values.toList()..sort();
        expect(values[0], Decimal.parse('3.33'));
        expect(values[1], Decimal.parse('3.33'));
        expect(values[2], Decimal.parse('3.34'));
      });

      test('produces consistent results with same seed', () {
        final amounts = {
          'alice': Decimal.parse('3.333333'),
          'bob': Decimal.parse('3.333333'),
          'charlie': Decimal.parse('3.333333'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.random,
        );

        // If we provide the same seed, should get same result
        final result1 = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
          randomSeed: 12345,
        );

        final result2 = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
          randomSeed: 12345,
        );

        expect(result1, result2);
      });
    });

    group('roundAmounts - different rounding modes', () {
      test('applies roundHalfUp correctly', () {
        final amounts = {
          'alice': Decimal.parse('1.235'),
          'bob': Decimal.parse('1.245'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        expect(result['alice'], Decimal.parse('1.24'));
        expect(result['bob'], Decimal.parse('1.25'));
      });

      test('applies roundHalfEven correctly', () {
        final amounts = {
          'alice': Decimal.parse('1.235'), // Should round to 1.24 (even)
          'bob': Decimal.parse('1.245'),   // Should round to 1.24 (even)
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfEven,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // Both round to nearest even
        expect(result['alice'], Decimal.parse('1.24'));
        expect(result['bob'], Decimal.parse('1.24'));
      });

      test('applies floor correctly', () {
        final amounts = {
          'alice': Decimal.parse('1.239'),
          'bob': Decimal.parse('1.999'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.floor,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        expect(result['alice'], Decimal.parse('1.23'));
        expect(result['bob'], Decimal.parse('2.00')); // Floor distributes remainder
      });

      test('applies ceil correctly', () {
        final amounts = {
          'alice': Decimal.parse('1.231'),
          'bob': Decimal.parse('1.001'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.ceil,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        expect(result['alice'], Decimal.parse('1.23')); // Adjusted for remainder
        expect(result['bob'], Decimal.parse('1.01'));
      });
    });

    group('roundAmounts - edge cases', () {
      test('handles single participant (no distribution needed)', () {
        final amounts = {
          'alice': Decimal.parse('10.123'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        expect(result['alice'], Decimal.parse('10.12'));
      });

      test('handles amounts that round perfectly (no remainder)', () {
        final amounts = {
          'alice': Decimal.parse('10.00'),
          'bob': Decimal.parse('20.00'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        expect(result['alice'], Decimal.parse('10.00'));
        expect(result['bob'], Decimal.parse('20.00'));
      });

      test('handles zero amounts', () {
        final amounts = {
          'alice': Decimal.zero,
          'bob': Decimal.parse('10.00'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        expect(result['alice'], Decimal.zero);
        expect(result['bob'], Decimal.parse('10.00'));
      });

      test('handles BHD currency (3 decimal places)', () {
        final amounts = {
          'alice': Decimal.parse('1.66666666'),
          'bob': Decimal.parse('1.66666666'),
          'charlie': Decimal.parse('1.66666666'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.001'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'BHD',
        );

        // Total: 5.000
        final total = result.values.fold(
          Decimal.zero,
          (sum, amount) => sum + amount,
        );
        expect(total, Decimal.parse('5.000'));

        // All amounts should have 3 decimal places
        result.values.forEach((amount) {
          expect(amount.scale, lessThanOrEqualTo(3));
        });
      });

      test('handles very small remainders that round to zero', () {
        final amounts = {
          'alice': Decimal.parse('10.001'),
          'bob': Decimal.parse('10.001'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // $20.002 → $20.00 (remainder too small to distribute)
        expect(result['alice'], Decimal.parse('10.00'));
        expect(result['bob'], Decimal.parse('10.00'));
      });

      test('handles negative amounts (discounts)', () {
        final amounts = {
          'alice': Decimal.parse('-5.555'),
          'bob': Decimal.parse('10.00'),
        };

        final config = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final result = service.roundAmounts(
          amounts: amounts,
          config: config,
          currencyCode: 'USD',
        );

        // -5.555 rounds to -5.56
        expect(result['alice'], Decimal.parse('-5.56'));
        expect(result['bob'], Decimal.parse('10.01')); // Gets remainder
      });
    });

    group('calculateRemainder', () {
      test('calculates remainder after rounding', () {
        final amounts = {
          'alice': Decimal.parse('3.333333'),
          'bob': Decimal.parse('3.333333'),
          'charlie': Decimal.parse('3.333333'),
        };

        final precision = Decimal.parse('0.01');

        final remainder = service.calculateRemainder(
          amounts: amounts,
          precision: precision,
        );

        // Original total: 9.999999
        // Rounded total: 9.99
        // Remainder: 0.009999 (but expressed in precision units)
        expect(remainder, Decimal.parse('0.01'));
      });

      test('returns zero for perfectly rounded amounts', () {
        final amounts = {
          'alice': Decimal.parse('10.00'),
          'bob': Decimal.parse('20.00'),
        };

        final precision = Decimal.parse('0.01');

        final remainder = service.calculateRemainder(
          amounts: amounts,
          precision: precision,
        );

        expect(remainder, Decimal.zero);
      });
    });
  });
}
