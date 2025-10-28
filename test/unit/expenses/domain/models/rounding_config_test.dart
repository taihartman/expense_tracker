import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_config.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/remainder_distribution_mode.dart';

void main() {
  group('RoundingConfig', () {
    test('creates valid config with USD precision (0.01)', () {
      final config = RoundingConfig(
        precision: Decimal.parse('0.01'),
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.largestShare,
      );

      expect(config.precision, Decimal.parse('0.01'));
      expect(config.mode, RoundingMode.roundHalfUp);
      expect(config.distributeRemainderTo, RemainderDistributionMode.largestShare);
    });

    test('creates valid config with VND precision (1)', () {
      final config = RoundingConfig(
        precision: Decimal.parse('1'),
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.payer,
      );

      expect(config.precision, Decimal.parse('1'));
    });

    test('validates precision is positive', () {
      expect(
        () => RoundingConfig(
          precision: Decimal.parse('0'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
        throwsArgumentError,
      );

      expect(
        () => RoundingConfig(
          precision: Decimal.parse('-0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
        throwsArgumentError,
      );
    });

    test('supports equality comparison', () {
      final config1 = RoundingConfig(
        precision: Decimal.parse('0.01'),
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.largestShare,
      );

      final config2 = RoundingConfig(
        precision: Decimal.parse('0.01'),
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.largestShare,
      );

      expect(config1, equals(config2));
    });

    test('supports copyWith', () {
      final config = RoundingConfig(
        precision: Decimal.parse('0.01'),
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.largestShare,
      );

      final updated = config.copyWith(
        mode: RoundingMode.roundHalfEven,
      );

      expect(updated.precision, Decimal.parse('0.01'));
      expect(updated.mode, RoundingMode.roundHalfEven);
      expect(updated.distributeRemainderTo, RemainderDistributionMode.largestShare);
    });
  });
}
