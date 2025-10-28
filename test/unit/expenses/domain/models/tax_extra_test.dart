import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/tax_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';

void main() {
  group('TaxExtra', () {
    group('percent type', () {
      test('creates valid percent tax with base', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );

        expect(tax.type, 'percent');
        expect(tax.value, Decimal.parse('8.875'));
        expect(tax.base, PercentBase.preTaxItemSubtotals);
      });

      test('creates percent tax with taxable items only base', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('10'),
          base: PercentBase.taxableItemSubtotalsOnly,
        );

        expect(tax.base, PercentBase.taxableItemSubtotalsOnly);
      });

      test('creates percent tax with post-discount base', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('7.5'),
          base: PercentBase.postDiscountItemSubtotals,
        );

        expect(tax.base, PercentBase.postDiscountItemSubtotals);
      });

      test('validates value is positive for percent type', () {
        expect(
          () => TaxExtra.percent(
            value: Decimal.parse('0'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          throwsArgumentError,
        );

        expect(
          () => TaxExtra.percent(
            value: Decimal.parse('-5'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          throwsArgumentError,
        );
      });

      test('validates base is required for percent type', () {
        expect(
          () =>
              TaxExtra(type: 'percent', value: Decimal.parse('10'), base: null),
          throwsArgumentError,
        );
      });

      test('allows high percentage values', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('25.5'),
          base: PercentBase.preTaxItemSubtotals,
        );

        expect(tax.value, Decimal.parse('25.5'));
      });

      test('allows fractional percentage values', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );

        expect(tax.value, Decimal.parse('8.875'));
      });
    });

    group('amount type', () {
      test('creates valid amount tax', () {
        final tax = TaxExtra.amount(value: Decimal.parse('5.00'));

        expect(tax.type, 'amount');
        expect(tax.value, Decimal.parse('5.00'));
        expect(tax.base, isNull);
      });

      test('validates value is positive for amount type', () {
        expect(
          () => TaxExtra.amount(value: Decimal.parse('0')),
          throwsArgumentError,
        );

        expect(
          () => TaxExtra.amount(value: Decimal.parse('-10.00')),
          throwsArgumentError,
        );
      });

      test('validates base must be null for amount type', () {
        expect(
          () => TaxExtra(
            type: 'amount',
            value: Decimal.parse('5.00'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          throwsArgumentError,
        );
      });

      test('allows large amount values', () {
        final tax = TaxExtra.amount(value: Decimal.parse('1000.00'));

        expect(tax.value, Decimal.parse('1000.00'));
      });

      test('allows small amount values', () {
        final tax = TaxExtra.amount(value: Decimal.parse('0.01'));

        expect(tax.value, Decimal.parse('0.01'));
      });
    });

    group('validation', () {
      test('validates type is either percent or amount', () {
        expect(
          () =>
              TaxExtra(type: 'invalid', value: Decimal.parse('10'), base: null),
          throwsArgumentError,
        );
      });

      test('validates value is always positive regardless of type', () {
        expect(
          () => TaxExtra(
            type: 'percent',
            value: Decimal.parse('-1'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          throwsArgumentError,
        );

        expect(
          () =>
              TaxExtra(type: 'amount', value: Decimal.parse('-1'), base: null),
          throwsArgumentError,
        );
      });
    });

    test('supports equality comparison', () {
      final tax1 = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final tax2 = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );

      expect(tax1, equals(tax2));
    });

    test('distinguishes different taxes', () {
      final tax1 = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final tax2 = TaxExtra.percent(
        value: Decimal.parse('10'),
        base: PercentBase.preTaxItemSubtotals,
      );

      expect(tax1, isNot(equals(tax2)));
    });

    test('distinguishes percent vs amount type', () {
      final tax1 = TaxExtra.percent(
        value: Decimal.parse('10'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final tax2 = TaxExtra.amount(value: Decimal.parse('10'));

      expect(tax1, isNot(equals(tax2)));
    });

    test('distinguishes different bases', () {
      final tax1 = TaxExtra.percent(
        value: Decimal.parse('10'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final tax2 = TaxExtra.percent(
        value: Decimal.parse('10'),
        base: PercentBase.taxableItemSubtotalsOnly,
      );

      expect(tax1, isNot(equals(tax2)));
    });

    test('supports copyWith for percent tax', () {
      final tax = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final updated = tax.copyWith(
        value: Decimal.parse('10'),
        base: PercentBase.postDiscountItemSubtotals,
      );

      expect(updated.type, 'percent');
      expect(updated.value, Decimal.parse('10'));
      expect(updated.base, PercentBase.postDiscountItemSubtotals);
    });

    test('supports copyWith for amount tax', () {
      final tax = TaxExtra.amount(value: Decimal.parse('5.00'));

      final updated = tax.copyWith(value: Decimal.parse('7.50'));

      expect(updated.type, 'amount');
      expect(updated.value, Decimal.parse('7.50'));
      expect(updated.base, isNull);
    });

    test('supports copyWith with partial updates', () {
      final tax = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final updated = tax.copyWith(base: PercentBase.taxableItemSubtotalsOnly);

      expect(updated.type, 'percent');
      expect(updated.value, Decimal.parse('8.875'));
      expect(updated.base, PercentBase.taxableItemSubtotalsOnly);
    });

    test('supports changing type from percent to amount', () {
      final tax = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final updated = tax.copyWith(
        type: 'amount',
        value: Decimal.parse('5.00'),
        base: null,
      );

      expect(updated.type, 'amount');
      expect(updated.value, Decimal.parse('5.00'));
      expect(updated.base, isNull);
    });

    test('supports changing type from amount to percent', () {
      final tax = TaxExtra.amount(value: Decimal.parse('5.00'));

      final updated = tax.copyWith(
        type: 'percent',
        value: Decimal.parse('10'),
        base: PercentBase.preTaxItemSubtotals,
      );

      expect(updated.type, 'percent');
      expect(updated.value, Decimal.parse('10'));
      expect(updated.base, PercentBase.preTaxItemSubtotals);
    });
  });
}
