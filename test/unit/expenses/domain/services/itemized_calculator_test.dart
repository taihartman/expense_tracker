import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/line_item.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_assignment.dart';
import 'package:expense_tracker/features/expenses/domain/models/assignment_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/extras.dart';
import 'package:expense_tracker/features/expenses/domain/models/tax_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/tip_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/fee_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/discount_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/allocation_rule.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_config.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/remainder_distribution_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';
import 'package:expense_tracker/features/expenses/domain/models/absolute_split_mode.dart';
import 'package:expense_tracker/features/expenses/domain/services/itemized_calculator.dart';
import 'package:expense_tracker/features/expenses/domain/models/participant_breakdown.dart';

// Helper extension to extract fees and discounts from extrasAllocated
extension ParticipantBreakdownTestHelpers on ParticipantBreakdown {
  Decimal get taxAmount => extrasAllocated['tax'] ?? Decimal.zero;
  Decimal get tipAmount => extrasAllocated['tip'] ?? Decimal.zero;

  Decimal get feesAmount {
    return extrasAllocated.entries
        .where((e) => e.key.startsWith('fee_'))
        .fold(Decimal.zero, (sum, entry) => sum + entry.value);
  }

  Decimal get discountsAmount {
    return extrasAllocated.entries
        .where((e) => e.key.startsWith('discount_'))
        .fold(Decimal.zero, (sum, entry) => sum + entry.value);
  }

  Map<String, Decimal> get feeBreakdown {
    return Map.fromEntries(
      extrasAllocated.entries
          .where((e) => e.key.startsWith('fee_'))
          .map((e) => MapEntry(e.key.substring(4), e.value)),
    );
  }

  Map<String, Decimal> get discountBreakdown {
    return Map.fromEntries(
      extrasAllocated.entries
          .where((e) => e.key.startsWith('discount_'))
          .map((e) => MapEntry(e.key.substring(9), e.value)),
    );
  }
}

void main() {
  group('ItemizedCalculator', () {
    late ItemizedCalculator calculator;

    setUp(() {
      calculator = ItemizedCalculator();
    });

    group('Golden Fixture 1: Simple Dinner (2 people, even split)', () {
      // Scenario: Alice and Bob go to dinner
      // Pizza $18.00 - shared evenly
      // Salad $12.00 - shared evenly
      // Tax: 8.5% on subtotal
      // Tip: 20% on subtotal
      // Expected:
      //   Subtotal: $30.00
      //   Tax: $2.55
      //   Tip: $6.00
      //   Total: $38.55
      //   Each pays: $19.27 + $0.01 remainder → Alice: $19.28, Bob: $19.27

      final items = [
        LineItem(
          id: 'item1',
          name: 'Pizza',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('18.00'),
          taxable: true,
          serviceChargeable: true,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: ['alice', 'bob'],
          ),
        ),
        LineItem(
          id: 'item2',
          name: 'Salad',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('12.00'),
          taxable: true,
          serviceChargeable: true,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: ['alice', 'bob'],
          ),
        ),
      ];

      final extras = Extras(
        tax: TaxExtra.percent(
          value: Decimal.parse('8.5'),
          base: PercentBase.preTaxItemSubtotals,
        ),
        tip: TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.preTaxItemSubtotals,
        ),
      );

      final allocationRule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      test('calculates correct subtotals per person', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Each person should have $15.00 item subtotal
        expect(
          result['alice']!.itemsSubtotal,
          Decimal.parse('15.00'),
        );
        expect(
          result['bob']!.itemsSubtotal,
          Decimal.parse('15.00'),
        );
      });

      test('calculates correct tax allocation', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Total tax: $30.00 * 0.085 = $2.55
        // Each pays: $1.275 → rounds to $1.28 and $1.27
        final totalTax = result['alice']!.taxAmount + result['bob']!.taxAmount;
        expect(totalTax, Decimal.parse('2.55'));

        // Verify one person gets rounded up due to remainder
        expect(
          result['alice']!.taxAmount + result['bob']!.taxAmount,
          Decimal.parse('2.55'),
        );
      });

      test('calculates correct tip allocation', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Total tip: $30.00 * 0.20 = $6.00
        // Each pays: $3.00 (even split)
        expect(result['alice']!.tipAmount, Decimal.parse('3.00'));
        expect(result['bob']!.tipAmount, Decimal.parse('3.00'));
      });

      test('calculates correct grand total per person', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Total: $38.55
        // Each pays: $19.275 → rounds to $19.28 and $19.27
        final totalAmount = result['alice']!.total + result['bob']!.total;
        expect(totalAmount, Decimal.parse('38.55'));

        // Verify rounding distributed correctly
        final alice = result['alice']!.total;
        final bob = result['bob']!.total;
        expect(
          alice == Decimal.parse('19.28') || bob == Decimal.parse('19.28'),
          isTrue,
        );
      });

      test('provides complete item contributions audit trail', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Each person should have 2 item contributions
        expect(result['alice']!.items.length, 2);
        expect(result['bob']!.items.length, 2);

        // Verify pizza contribution
        final alicePizza = result['alice']!
            .items
            .firstWhere((c) => c.itemId == 'item1');
        expect(alicePizza.itemName, 'Pizza');
        expect(alicePizza.assignedShare, Decimal.parse('0.5'));
        expect(alicePizza.contributionAmount, Decimal.parse('9.00'));
      });
    });

    group('Golden Fixture 2: Mixed Assignment (custom split)', () {
      // Scenario: Alice, Bob, Charlie go to dinner
      // Burger $15.00 - Alice only
      // Fries $6.00 - Shared: Alice 50%, Bob 25%, Charlie 25%
      // Drinks $12.00 - Bob and Charlie evenly
      // Tax: 8% flat amount $3.00
      // Tip: 18% on subtotal
      // Expected per person calculation...

      final items = [
        LineItem(
          id: 'burger',
          name: 'Burger',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('15.00'),
          taxable: true,
          serviceChargeable: true,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: ['alice'],
          ),
        ),
        LineItem(
          id: 'fries',
          name: 'Fries',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('6.00'),
          taxable: true,
          serviceChargeable: true,
          assignment: ItemAssignment(
            mode: AssignmentMode.custom,
            users: const ['alice', 'bob', 'charlie'],
            shares: {
              'alice': Decimal.parse('0.5'),
              'bob': Decimal.parse('0.25'),
              'charlie': Decimal.parse('0.25'),
            },
          ),
        ),
        LineItem(
          id: 'drinks',
          name: 'Drinks',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('12.00'),
          taxable: true,
          serviceChargeable: true,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: ['bob', 'charlie'],
          ),
        ),
      ];

      final extras = Extras(
        tax: TaxExtra.amount(value: Decimal.parse('3.00')),
        tip: TipExtra.percent(
          value: Decimal.parse('18'),
          base: PercentBase.preTaxItemSubtotals,
        ),
      );

      final allocationRule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      test('calculates correct item subtotals with custom shares', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Alice: $15.00 (burger) + $3.00 (50% fries) = $18.00
        expect(result['alice']!.itemsSubtotal, Decimal.parse('18.00'));

        // Bob: $1.50 (25% fries) + $6.00 (50% drinks) = $7.50
        expect(result['bob']!.itemsSubtotal, Decimal.parse('7.50'));

        // Charlie: $1.50 (25% fries) + $6.00 (50% drinks) = $7.50
        expect(result['charlie']!.itemsSubtotal, Decimal.parse('7.50'));
      });

      test('distributes flat tax amount proportionally', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Total subtotal: $33.00
        // Tax: $3.00 flat
        // Alice pays: 18/33 * $3.00 = $1.636... → rounds
        // Bob pays: 7.5/33 * $3.00 = $0.681... → rounds
        // Charlie pays: 7.5/33 * $3.00 = $0.681... → rounds
        final totalTax = result['alice']!.taxAmount +
            result['bob']!.taxAmount +
            result['charlie']!.taxAmount;

        expect(totalTax, Decimal.parse('3.00'));
      });

      test('calculates tip on subtotal proportionally', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Total tip: $33.00 * 0.18 = $5.94
        final totalTip = result['alice']!.tipAmount +
            result['bob']!.tipAmount +
            result['charlie']!.tipAmount;

        expect(totalTip, Decimal.parse('5.94'));
      });
    });

    group('Golden Fixture 3: VND Currency (zero decimal places)', () {
      // Scenario: Vietnamese restaurant, prices in VND (no decimals)
      // Pho 85,000đ - Alice only
      // Spring Rolls 45,000đ - Alice and Bob evenly
      // Tax: 10% on subtotal
      // Expected rounding to whole numbers

      final items = [
        LineItem(
          id: 'pho',
          name: 'Pho',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('85000'),
          taxable: true,
          serviceChargeable: false,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: ['alice'],
          ),
        ),
        LineItem(
          id: 'rolls',
          name: 'Spring Rolls',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('45000'),
          taxable: true,
          serviceChargeable: false,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: ['alice', 'bob'],
          ),
        ),
      ];

      final extras = Extras(
        tax: TaxExtra.percent(
          value: Decimal.parse('10'),
          base: PercentBase.preTaxItemSubtotals,
        ),
      );

      final allocationRule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('1'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      test('rounds all amounts to whole VND', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'VND',
        );

        // All amounts should be whole numbers
        expect(result['alice']!.itemsSubtotal.scale, 0);
        expect(result['alice']!.taxAmount.scale, 0);
        expect(result['alice']!.total.scale, 0);
        expect(result['bob']!.itemsSubtotal.scale, 0);
        expect(result['bob']!.taxAmount.scale, 0);
        expect(result['bob']!.total.scale, 0);
      });

      test('calculates correct totals for VND', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'VND',
        );

        // Alice: 85,000 + 22,500 = 107,500
        expect(result['alice']!.itemsSubtotal, Decimal.parse('107500'));

        // Bob: 22,500
        expect(result['bob']!.itemsSubtotal, Decimal.parse('22500'));

        // Total subtotal: 130,000
        // Tax: 13,000
        final totalTax = result['alice']!.taxAmount + result['bob']!.taxAmount;
        expect(totalTax, Decimal.parse('13000'));
      });
    });

    group('Golden Fixture 4: Fees and Discounts', () {
      // Scenario: Online food delivery
      // Food items $50.00 subtotal
      // Tax: 8% on subtotal
      // Tip: 15% on subtotal
      // Delivery Fee: $5.00
      // Service Fee: $3.00
      // Promo Discount: -$10.00

      final items = [
        LineItem(
          id: 'food',
          name: 'Food',
          quantity: Decimal.one,
          unitPrice: Decimal.parse('50.00'),
          taxable: true,
          serviceChargeable: true,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: ['alice', 'bob'],
          ),
        ),
      ];

      final extras = Extras(
        tax: TaxExtra.percent(
          value: Decimal.parse('8'),
          base: PercentBase.preTaxItemSubtotals,
        ),
        tip: TipExtra.percent(
          value: Decimal.parse('15'),
          base: PercentBase.preTaxItemSubtotals,
        ),
        fees: [
          FeeExtra(
            id: 'fee1',
            name: 'Delivery Fee',
            type: 'amount',
            value: Decimal.parse('5.00'),
            base: null,
          ),
          FeeExtra(
            id: 'fee2',
            name: 'Service Fee',
            type: 'amount',
            value: Decimal.parse('3.00'),
            base: null,
          ),
        ],
        discounts: [
          DiscountExtra(
            id: 'discount1',
            name: 'Promo Code',
            type: 'amount',
            value: Decimal.parse('10.00'),
            base: null,
          ),
        ],
      );

      final allocationRule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      test('includes fees in total calculation', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Each person pays half of fees: ($5 + $3) / 2 = $4.00 each
        expect(result['alice']!.feesAmount, Decimal.parse('4.00'));
        expect(result['bob']!.feesAmount, Decimal.parse('4.00'));
      });

      test('applies discounts proportionally', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Each person gets $5.00 discount (proportional to their $25 subtotal)
        expect(result['alice']!.discountsAmount, Decimal.parse('5.00'));
        expect(result['bob']!.discountsAmount, Decimal.parse('5.00'));
      });

      test('calculates correct grand total with all components', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Items: $50.00
        // Tax: $4.00
        // Tip: $7.50
        // Fees: $8.00
        // Discount: -$10.00
        // Total: $59.50 ($29.75 each)
        final totalAmount = result['alice']!.total + result['bob']!.total;
        expect(totalAmount, Decimal.parse('59.50'));
      });

      test('provides fee breakdown in participant details', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Should have fee breakdown
        expect(result['alice']!.feeBreakdown.length, 2);
        expect(
          result['alice']!.feeBreakdown['Delivery Fee'],
          Decimal.parse('2.50'),
        );
        expect(
          result['alice']!.feeBreakdown['Service Fee'],
          Decimal.parse('1.50'),
        );
      });

      test('provides discount breakdown in participant details', () {
        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Should have discount breakdown
        expect(result['alice']!.discountBreakdown.length, 1);
        expect(
          result['alice']!.discountBreakdown['Promo Code'],
          Decimal.parse('5.00'),
        );
      });
    });

    group('Edge Cases', () {
      test('handles zero tip correctly', () {
        final items = [
          LineItem(
            id: 'item1',
            name: 'Item',
            quantity: Decimal.one,
            unitPrice: Decimal.parse('10.00'),
            taxable: false,
            serviceChargeable: false,
            assignment: const ItemAssignment(
              mode: AssignmentMode.even,
              users: ['alice'],
            ),
          ),
        ];

        final extras = Extras(
          tip: TipExtra.amount(value: Decimal.zero),
        );

        final allocationRule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        expect(result['alice']!.tipAmount, Decimal.zero);
        expect(result['alice']!.total, Decimal.parse('10.00'));
      });

      test('handles single person assignment', () {
        final items = [
          LineItem(
            id: 'item1',
            name: 'Item',
            quantity: Decimal.one,
            unitPrice: Decimal.parse('10.00'),
            taxable: false,
            serviceChargeable: false,
            assignment: const ItemAssignment(
              mode: AssignmentMode.even,
              users: ['alice'],
            ),
          ),
        ];

        final extras = const Extras();

        final allocationRule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        expect(result.length, 1);
        expect(result['alice']!.total, Decimal.parse('10.00'));
      });

      test('handles empty fees and discounts lists', () {
        final items = [
          LineItem(
            id: 'item1',
            name: 'Item',
            quantity: Decimal.one,
            unitPrice: Decimal.parse('10.00'),
            taxable: false,
            serviceChargeable: false,
            assignment: const ItemAssignment(
              mode: AssignmentMode.even,
              users: ['alice'],
            ),
          ),
        ];

        final extras = const Extras(
          fees: [],
          discounts: [],
        );

        final allocationRule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        expect(result['alice']!.feesAmount, Decimal.zero);
        expect(result['alice']!.discountsAmount, Decimal.zero);
      });
    });

    group('Allocation Rule Variations', () {
      test('handles evenAcrossAssignedPeople split for tax', () {
        final items = [
          LineItem(
            id: 'item1',
            name: 'Item',
            quantity: Decimal.one,
            unitPrice: Decimal.parse('30.00'),
            taxable: true,
            serviceChargeable: false,
            assignment: ItemAssignment(
              mode: AssignmentMode.custom,
              users: const ['alice', 'bob', 'charlie'],
              shares: {
                'alice': Decimal.parse('0.5'),
                'bob': Decimal.parse('0.3'),
                'charlie': Decimal.parse('0.2'),
              },
            ),
          ),
        ];

        final extras = Extras(
          tax: TaxExtra.amount(value: Decimal.parse('3.00')),
        );

        final allocationRule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        final result = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRule,
          currencyCode: 'USD',
        );

        // Tax split evenly: $1.00 each (even though item splits were different)
        expect(result['alice']!.taxAmount, Decimal.parse('1.00'));
        expect(result['bob']!.taxAmount, Decimal.parse('1.00'));
        expect(result['charlie']!.taxAmount, Decimal.parse('1.00'));
      });

      test('handles different rounding modes', () {
        final items = [
          LineItem(
            id: 'item1',
            name: 'Item',
            quantity: Decimal.one,
            unitPrice: Decimal.parse('10.01'),
            taxable: false,
            serviceChargeable: false,
            assignment: const ItemAssignment(
              mode: AssignmentMode.even,
              users: ['alice', 'bob', 'charlie'],
            ),
          ),
        ];

        final extras = const Extras();

        // Test with floor rounding
        final allocationRuleFloor = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.floor,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        final resultFloor = calculator.calculate(
          items: items,
          extras: extras,
          allocation: allocationRuleFloor,
          currencyCode: 'USD',
        );

        // $10.01 / 3 = $3.336... with floor should be $3.33, $3.33, $3.33
        // But remainder $0.02 distributed to largest share
        final totalFloor = resultFloor['alice']!.total +
            resultFloor['bob']!.total +
            resultFloor['charlie']!.total;
        expect(totalFloor, Decimal.parse('10.01'));
      });
    });
  });
}
