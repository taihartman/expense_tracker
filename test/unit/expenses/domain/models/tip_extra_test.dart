import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/tip_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';

void main() {
  group('TipExtra', () {
    group('percent type', () {
      test('creates valid percent tip with base', () {
        final tip = TipExtra.percent(
          value: Decimal.parse('18'),
          base: PercentBase.preTaxItemSubtotals,
        );

        expect(tip.type, 'percent');
        expect(tip.value, Decimal.parse('18'));
        expect(tip.base, PercentBase.preTaxItemSubtotals);
      });

      test('creates percent tip with post-tax base', () {
        final tip = TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.postTaxSubtotals,
        );

        expect(tip.base, PercentBase.postTaxSubtotals);
      });

      test('creates percent tip with post-fees base', () {
        final tip = TipExtra.percent(
          value: Decimal.parse('15'),
          base: PercentBase.postFeesSubtotals,
        );

        expect(tip.base, PercentBase.postFeesSubtotals);
      });

      test('allows zero tip for percent type', () {
        final tip = TipExtra.percent(
          value: Decimal.zero,
          base: PercentBase.preTaxItemSubtotals,
        );

        expect(tip.value, Decimal.zero);
      });

      test('validates value is non-negative for percent type', () {
        // Zero is allowed
        expect(
          () => TipExtra.percent(
            value: Decimal.zero,
            base: PercentBase.preTaxItemSubtotals,
          ),
          returnsNormally,
        );

        // Negative is not allowed
        expect(
          () => TipExtra.percent(
            value: Decimal.parse('-5'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          throwsArgumentError,
        );
      });

      test('validates base is required for percent type', () {
        expect(
          () => TipExtra(
            type: 'percent',
            value: Decimal.parse('15'),
            base: null,
          ),
          throwsArgumentError,
        );
      });

      test('allows common tip percentages', () {
        final tip15 = TipExtra.percent(
          value: Decimal.parse('15'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final tip18 = TipExtra.percent(
          value: Decimal.parse('18'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final tip20 = TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final tip25 = TipExtra.percent(
          value: Decimal.parse('25'),
          base: PercentBase.preTaxItemSubtotals,
        );

        expect(tip15.value, Decimal.parse('15'));
        expect(tip18.value, Decimal.parse('18'));
        expect(tip20.value, Decimal.parse('20'));
        expect(tip25.value, Decimal.parse('25'));
      });

      test('allows fractional percentage values', () {
        final tip = TipExtra.percent(
          value: Decimal.parse('17.5'),
          base: PercentBase.postTaxSubtotals,
        );

        expect(tip.value, Decimal.parse('17.5'));
      });

      test('allows very high tip percentages', () {
        final tip = TipExtra.percent(
          value: Decimal.parse('100'),
          base: PercentBase.preTaxItemSubtotals,
        );

        expect(tip.value, Decimal.parse('100'));
      });
    });

    group('amount type', () {
      test('creates valid amount tip', () {
        final tip = TipExtra.amount(
          value: Decimal.parse('10.00'),
        );

        expect(tip.type, 'amount');
        expect(tip.value, Decimal.parse('10.00'));
        expect(tip.base, isNull);
      });

      test('allows zero tip for amount type', () {
        final tip = TipExtra.amount(
          value: Decimal.zero,
        );

        expect(tip.value, Decimal.zero);
      });

      test('validates value is non-negative for amount type', () {
        // Zero is allowed
        expect(
          () => TipExtra.amount(
            value: Decimal.zero,
          ),
          returnsNormally,
        );

        // Negative is not allowed
        expect(
          () => TipExtra.amount(
            value: Decimal.parse('-5.00'),
          ),
          throwsArgumentError,
        );
      });

      test('validates base must be null for amount type', () {
        expect(
          () => TipExtra(
            type: 'amount',
            value: Decimal.parse('10.00'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          throwsArgumentError,
        );
      });

      test('allows large amount values', () {
        final tip = TipExtra.amount(
          value: Decimal.parse('500.00'),
        );

        expect(tip.value, Decimal.parse('500.00'));
      });

      test('allows small amount values', () {
        final tip = TipExtra.amount(
          value: Decimal.parse('0.50'),
        );

        expect(tip.value, Decimal.parse('0.50'));
      });
    });

    group('validation', () {
      test('validates type is either percent or amount', () {
        expect(
          () => TipExtra(
            type: 'invalid',
            value: Decimal.parse('15'),
            base: null,
          ),
          throwsArgumentError,
        );
      });

      test('validates value is always non-negative regardless of type', () {
        expect(
          () => TipExtra(
            type: 'percent',
            value: Decimal.parse('-1'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          throwsArgumentError,
        );

        expect(
          () => TipExtra(
            type: 'amount',
            value: Decimal.parse('-1'),
            base: null,
          ),
          throwsArgumentError,
        );
      });
    });

    group('difference from TaxExtra', () {
      test('tip allows zero value while tax does not', () {
        // Tip with zero should work
        expect(
          () => TipExtra.percent(
            value: Decimal.zero,
            base: PercentBase.preTaxItemSubtotals,
          ),
          returnsNormally,
        );

        expect(
          () => TipExtra.amount(
            value: Decimal.zero,
          ),
          returnsNormally,
        );
      });
    });

    test('supports equality comparison', () {
      final tip1 = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );

      final tip2 = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );

      expect(tip1, equals(tip2));
    });

    test('distinguishes different tips', () {
      final tip1 = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );

      final tip2 = TipExtra.percent(
        value: Decimal.parse('20'),
        base: PercentBase.postTaxSubtotals,
      );

      expect(tip1, isNot(equals(tip2)));
    });

    test('distinguishes percent vs amount type', () {
      final tip1 = TipExtra.percent(
        value: Decimal.parse('15'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final tip2 = TipExtra.amount(
        value: Decimal.parse('15'),
      );

      expect(tip1, isNot(equals(tip2)));
    });

    test('distinguishes different bases', () {
      final tip1 = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final tip2 = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );

      expect(tip1, isNot(equals(tip2)));
    });

    test('treats zero amount and zero percent as different', () {
      final tip1 = TipExtra.percent(
        value: Decimal.zero,
        base: PercentBase.preTaxItemSubtotals,
      );

      final tip2 = TipExtra.amount(
        value: Decimal.zero,
      );

      expect(tip1, isNot(equals(tip2)));
    });

    test('supports copyWith for percent tip', () {
      final tip = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final updated = tip.copyWith(
        value: Decimal.parse('20'),
        base: PercentBase.postTaxSubtotals,
      );

      expect(updated.type, 'percent');
      expect(updated.value, Decimal.parse('20'));
      expect(updated.base, PercentBase.postTaxSubtotals);
    });

    test('supports copyWith for amount tip', () {
      final tip = TipExtra.amount(
        value: Decimal.parse('10.00'),
      );

      final updated = tip.copyWith(
        value: Decimal.parse('15.00'),
      );

      expect(updated.type, 'amount');
      expect(updated.value, Decimal.parse('15.00'));
      expect(updated.base, isNull);
    });

    test('supports copyWith with partial updates', () {
      final tip = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final updated = tip.copyWith(
        base: PercentBase.postTaxSubtotals,
      );

      expect(updated.type, 'percent');
      expect(updated.value, Decimal.parse('18'));
      expect(updated.base, PercentBase.postTaxSubtotals);
    });

    test('supports changing type from percent to amount', () {
      final tip = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );

      final updated = tip.copyWith(
        type: 'amount',
        value: Decimal.parse('10.00'),
        base: null,
      );

      expect(updated.type, 'amount');
      expect(updated.value, Decimal.parse('10.00'));
      expect(updated.base, isNull);
    });

    test('supports changing type from amount to percent', () {
      final tip = TipExtra.amount(
        value: Decimal.parse('10.00'),
      );

      final updated = tip.copyWith(
        type: 'percent',
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );

      expect(updated.type, 'percent');
      expect(updated.value, Decimal.parse('18'));
      expect(updated.base, PercentBase.postTaxSubtotals);
    });

    test('supports setting tip to zero via copyWith', () {
      final tip = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );

      final noTip = tip.copyWith(
        value: Decimal.zero,
      );

      expect(noTip.value, Decimal.zero);
    });
  });
}
