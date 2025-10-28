import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/extras.dart';
import 'package:expense_tracker/features/expenses/domain/models/tax_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/tip_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/fee_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/discount_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';

void main() {
  group('Extras', () {
    group('creation with various combinations', () {
      test('creates empty extras with all fields null/empty', () {
        final extras = const Extras(
          tax: null,
          tip: null,
          fees: [],
          discounts: [],
        );

        expect(extras.tax, isNull);
        expect(extras.tip, isNull);
        expect(extras.fees, isEmpty);
        expect(extras.discounts, isEmpty);
      });

      test('creates extras with only tax', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );

        final extras = Extras(
          tax: tax,
          tip: null,
          fees: const [],
          discounts: const [],
        );

        expect(extras.tax, tax);
        expect(extras.tip, isNull);
        expect(extras.fees, isEmpty);
        expect(extras.discounts, isEmpty);
      });

      test('creates extras with only tip', () {
        final tip = TipExtra.percent(
          value: Decimal.parse('18'),
          base: PercentBase.postTaxSubtotals,
        );

        final extras = Extras(
          tax: null,
          tip: tip,
          fees: const [],
          discounts: const [],
        );

        expect(extras.tax, isNull);
        expect(extras.tip, tip);
        expect(extras.fees, isEmpty);
        expect(extras.discounts, isEmpty);
      });

      test('creates extras with only fees', () {
        final fee1 = FeeExtra(
          id: 'fee1',
          name: 'Service Fee',
          type: 'percent',
          value: Decimal.parse('3'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final fee2 = FeeExtra(
          id: 'fee2',
          name: 'Delivery Fee',
          type: 'amount',
          value: Decimal.parse('5.00'),
          base: null,
        );

        final extras = Extras(
          tax: null,
          tip: null,
          fees: [fee1, fee2],
          discounts: const [],
        );

        expect(extras.tax, isNull);
        expect(extras.tip, isNull);
        expect(extras.fees, hasLength(2));
        expect(extras.fees[0], fee1);
        expect(extras.fees[1], fee2);
        expect(extras.discounts, isEmpty);
      });

      test('creates extras with only discounts', () {
        final discount1 = DiscountExtra(
          id: 'disc1',
          name: 'Happy Hour',
          type: 'percent',
          value: Decimal.parse('20'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final discount2 = DiscountExtra(
          id: 'disc2',
          name: 'Coupon',
          type: 'amount',
          value: Decimal.parse('10.00'),
          base: null,
        );

        final extras = Extras(
          tax: null,
          tip: null,
          fees: const [],
          discounts: [discount1, discount2],
        );

        expect(extras.tax, isNull);
        expect(extras.tip, isNull);
        expect(extras.fees, isEmpty);
        expect(extras.discounts, hasLength(2));
        expect(extras.discounts[0], discount1);
        expect(extras.discounts[1], discount2);
      });

      test('creates extras with tax and tip', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final tip = TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.postTaxSubtotals,
        );

        final extras = Extras(
          tax: tax,
          tip: tip,
          fees: const [],
          discounts: const [],
        );

        expect(extras.tax, tax);
        expect(extras.tip, tip);
        expect(extras.fees, isEmpty);
        expect(extras.discounts, isEmpty);
      });

      test('creates extras with all fields populated', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final tip = TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.postTaxSubtotals,
        );
        final fee = FeeExtra(
          id: 'fee1',
          name: 'Service Fee',
          type: 'percent',
          value: Decimal.parse('3'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final discount = DiscountExtra(
          id: 'disc1',
          name: 'Happy Hour',
          type: 'percent',
          value: Decimal.parse('15'),
          base: PercentBase.preTaxItemSubtotals,
        );

        final extras = Extras(
          tax: tax,
          tip: tip,
          fees: [fee],
          discounts: [discount],
        );

        expect(extras.tax, tax);
        expect(extras.tip, tip);
        expect(extras.fees, hasLength(1));
        expect(extras.fees[0], fee);
        expect(extras.discounts, hasLength(1));
        expect(extras.discounts[0], discount);
      });

      test('creates extras with multiple fees', () {
        final fee1 = FeeExtra(
          id: 'fee1',
          name: 'Service Fee',
          type: 'percent',
          value: Decimal.parse('3'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final fee2 = FeeExtra(
          id: 'fee2',
          name: 'Delivery Fee',
          type: 'amount',
          value: Decimal.parse('5.00'),
          base: null,
        );
        final fee3 = FeeExtra(
          id: 'fee3',
          name: 'Processing Fee',
          type: 'amount',
          value: Decimal.parse('2.50'),
          base: null,
        );

        final extras = Extras(
          tax: null,
          tip: null,
          fees: [fee1, fee2, fee3],
          discounts: const [],
        );

        expect(extras.fees, hasLength(3));
      });

      test('creates extras with multiple discounts', () {
        final discount1 = DiscountExtra(
          id: 'disc1',
          name: 'Happy Hour',
          type: 'percent',
          value: Decimal.parse('20'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final discount2 = DiscountExtra(
          id: 'disc2',
          name: 'Early Bird',
          type: 'percent',
          value: Decimal.parse('10'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final discount3 = DiscountExtra(
          id: 'disc3',
          name: 'Coupon',
          type: 'amount',
          value: Decimal.parse('5.00'),
          base: null,
        );

        final extras = Extras(
          tax: null,
          tip: null,
          fees: const [],
          discounts: [discount1, discount2, discount3],
        );

        expect(extras.discounts, hasLength(3));
      });
    });

    group('optional fields behavior', () {
      test('allows null tax', () {
        final extras = const Extras(
          tax: null,
          tip: null,
          fees: [],
          discounts: [],
        );

        expect(extras.tax, isNull);
      });

      test('allows null tip', () {
        final extras = const Extras(
          tax: null,
          tip: null,
          fees: [],
          discounts: [],
        );

        expect(extras.tip, isNull);
      });

      test('allows empty fees list', () {
        final extras = const Extras(
          tax: null,
          tip: null,
          fees: [],
          discounts: [],
        );

        expect(extras.fees, isEmpty);
      });

      test('allows empty discounts list', () {
        final extras = const Extras(
          tax: null,
          tip: null,
          fees: [],
          discounts: [],
        );

        expect(extras.discounts, isEmpty);
      });

      test('treats empty list and null consistently', () {
        // Note: fees and discounts should be lists, not null
        // But we test that empty list works correctly
        final extras1 = const Extras(
          tax: null,
          tip: null,
          fees: [],
          discounts: [],
        );

        final extras2 = const Extras(
          tax: null,
          tip: null,
          fees: [],
          discounts: [],
        );

        expect(extras1, equals(extras2));
      });
    });

    group('real-world scenarios', () {
      test('creates typical restaurant bill extras (tax + tip)', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final tip = TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.postTaxSubtotals,
        );

        final extras = Extras(
          tax: tax,
          tip: tip,
          fees: const [],
          discounts: const [],
        );

        expect(extras.tax, isNotNull);
        expect(extras.tip, isNotNull);
        expect(extras.fees, isEmpty);
        expect(extras.discounts, isEmpty);
      });

      test('creates delivery order extras (tax + delivery fee + tip)', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final deliveryFee = FeeExtra(
          id: 'delivery',
          name: 'Delivery Fee',
          type: 'amount',
          value: Decimal.parse('5.99'),
          base: null,
        );
        final tip = TipExtra.percent(
          value: Decimal.parse('18'),
          base: PercentBase.postTaxSubtotals,
        );

        final extras = Extras(
          tax: tax,
          tip: tip,
          fees: [deliveryFee],
          discounts: const [],
        );

        expect(extras.tax, isNotNull);
        expect(extras.tip, isNotNull);
        expect(extras.fees, hasLength(1));
        expect(extras.discounts, isEmpty);
      });

      test('creates happy hour bill extras (tax + discount + tip)', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.postDiscountItemSubtotals,
        );
        final happyHour = DiscountExtra(
          id: 'happy_hour',
          name: 'Happy Hour 50% Off',
          type: 'percent',
          value: Decimal.parse('50'),
          base: PercentBase.preTaxItemSubtotals,
        );
        final tip = TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.postTaxSubtotals,
        );

        final extras = Extras(
          tax: tax,
          tip: tip,
          fees: const [],
          discounts: [happyHour],
        );

        expect(extras.tax, isNotNull);
        expect(extras.tip, isNotNull);
        expect(extras.fees, isEmpty);
        expect(extras.discounts, hasLength(1));
      });

      test(
        'creates complex bill extras (tax + service fee + discount + tip)',
        () {
          final tax = TaxExtra.percent(
            value: Decimal.parse('8.875'),
            base: PercentBase.postDiscountItemSubtotals,
          );
          final serviceFee = FeeExtra(
            id: 'service',
            name: 'Service Fee',
            type: 'percent',
            value: Decimal.parse('18'),
            base: PercentBase.preTaxItemSubtotals,
          );
          final discount = DiscountExtra(
            id: 'coupon',
            name: '\$10 Off Coupon',
            type: 'amount',
            value: Decimal.parse('10.00'),
            base: null,
          );
          final tip = TipExtra.percent(
            value: Decimal.parse('20'),
            base: PercentBase.postTaxSubtotals,
          );

          final extras = Extras(
            tax: tax,
            tip: tip,
            fees: [serviceFee],
            discounts: [discount],
          );

          expect(extras.tax, isNotNull);
          expect(extras.tip, isNotNull);
          expect(extras.fees, hasLength(1));
          expect(extras.discounts, hasLength(1));
        },
      );

      test('creates no-tip scenario (tax only)', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );

        final extras = Extras(
          tax: tax,
          tip: null,
          fees: const [],
          discounts: const [],
        );

        expect(extras.tax, isNotNull);
        expect(extras.tip, isNull);
      });
    });

    test('supports equality comparison', () {
      final tax = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final tip = TipExtra.percent(
        value: Decimal.parse('20'),
        base: PercentBase.postTaxSubtotals,
      );

      final extras1 = Extras(
        tax: tax,
        tip: tip,
        fees: const [],
        discounts: const [],
      );

      final extras2 = Extras(
        tax: tax,
        tip: tip,
        fees: const [],
        discounts: const [],
      );

      expect(extras1, equals(extras2));
    });

    test('distinguishes different extras', () {
      final tax1 = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final tax2 = TaxExtra.percent(
        value: Decimal.parse('10'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final extras1 = Extras(
        tax: tax1,
        tip: null,
        fees: const [],
        discounts: const [],
      );

      final extras2 = Extras(
        tax: tax2,
        tip: null,
        fees: const [],
        discounts: const [],
      );

      expect(extras1, isNot(equals(extras2)));
    });

    test('supports copyWith for tax', () {
      final tax1 = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final tax2 = TaxExtra.percent(
        value: Decimal.parse('10'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final extras = Extras(
        tax: tax1,
        tip: null,
        fees: const [],
        discounts: const [],
      );

      final updated = extras.copyWith(tax: tax2);

      expect(updated.tax, tax2);
      expect(updated.tip, isNull);
      expect(updated.fees, isEmpty);
      expect(updated.discounts, isEmpty);
    });

    test('supports copyWith for tip', () {
      final tip1 = TipExtra.percent(
        value: Decimal.parse('18'),
        base: PercentBase.postTaxSubtotals,
      );
      final tip2 = TipExtra.percent(
        value: Decimal.parse('20'),
        base: PercentBase.postTaxSubtotals,
      );

      final extras = Extras(
        tax: null,
        tip: tip1,
        fees: const [],
        discounts: const [],
      );

      final updated = extras.copyWith(tip: tip2);

      expect(updated.tax, isNull);
      expect(updated.tip, tip2);
      expect(updated.fees, isEmpty);
      expect(updated.discounts, isEmpty);
    });

    test('supports copyWith for fees', () {
      final fee1 = FeeExtra(
        id: 'fee1',
        name: 'Service Fee',
        type: 'percent',
        value: Decimal.parse('3'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final fee2 = FeeExtra(
        id: 'fee2',
        name: 'Delivery Fee',
        type: 'amount',
        value: Decimal.parse('5.00'),
        base: null,
      );

      final extras = Extras(
        tax: null,
        tip: null,
        fees: [fee1],
        discounts: const [],
      );

      final updated = extras.copyWith(fees: [fee1, fee2]);

      expect(updated.fees, hasLength(2));
    });

    test('supports copyWith for discounts', () {
      final discount1 = DiscountExtra(
        id: 'disc1',
        name: 'Happy Hour',
        type: 'percent',
        value: Decimal.parse('20'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final discount2 = DiscountExtra(
        id: 'disc2',
        name: 'Coupon',
        type: 'amount',
        value: Decimal.parse('10.00'),
        base: null,
      );

      final extras = Extras(
        tax: null,
        tip: null,
        fees: const [],
        discounts: [discount1],
      );

      final updated = extras.copyWith(discounts: [discount1, discount2]);

      expect(updated.discounts, hasLength(2));
    });

    test('supports copyWith with multiple fields', () {
      final tax = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final tip = TipExtra.percent(
        value: Decimal.parse('20'),
        base: PercentBase.postTaxSubtotals,
      );

      final extras = const Extras(
        tax: null,
        tip: null,
        fees: [],
        discounts: [],
      );

      final updated = extras.copyWith(tax: tax, tip: tip);

      expect(updated.tax, tax);
      expect(updated.tip, tip);
    });

    test('supports removing fields via copyWith with null', () {
      final tax = TaxExtra.percent(
        value: Decimal.parse('8.875'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final tip = TipExtra.percent(
        value: Decimal.parse('20'),
        base: PercentBase.postTaxSubtotals,
      );

      final extras = Extras(
        tax: tax,
        tip: tip,
        fees: const [],
        discounts: const [],
      );

      final updated = extras.copyWith(tax: null, tip: null);

      expect(updated.tax, isNull);
      expect(updated.tip, isNull);
    });

    test('supports clearing lists via copyWith', () {
      final fee = FeeExtra(
        id: 'fee1',
        name: 'Service Fee',
        type: 'percent',
        value: Decimal.parse('3'),
        base: PercentBase.preTaxItemSubtotals,
      );
      final discount = DiscountExtra(
        id: 'disc1',
        name: 'Happy Hour',
        type: 'percent',
        value: Decimal.parse('20'),
        base: PercentBase.preTaxItemSubtotals,
      );

      final extras = Extras(
        tax: null,
        tip: null,
        fees: [fee],
        discounts: [discount],
      );

      final updated = extras.copyWith(fees: const [], discounts: const []);

      expect(updated.fees, isEmpty);
      expect(updated.discounts, isEmpty);
    });
  });
}
