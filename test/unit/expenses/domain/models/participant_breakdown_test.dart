import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/participant_breakdown.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_contribution.dart';

void main() {
  group('ParticipantBreakdown', () {
    test('creates valid participant breakdown with all fields', () {
      final item1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('25.00'),
        extrasAllocated: {
          'tax': Decimal.parse('2.22'),
          'tip': Decimal.parse('5.00'),
          'fees': Decimal.parse('1.50'),
          'discounts': Decimal.parse('-3.00'),
        },
        roundedAdjustment: Decimal.parse('0.01'),
        total: Decimal.parse('30.73'),
        items: [item1],
      );

      expect(breakdown.userId, 'user1');
      expect(breakdown.itemsSubtotal, Decimal.parse('25.00'));
      expect(breakdown.extrasAllocated['tax'], Decimal.parse('2.22'));
      expect(breakdown.extrasAllocated['tip'], Decimal.parse('5.00'));
      expect(breakdown.extrasAllocated['fees'], Decimal.parse('1.50'));
      expect(breakdown.extrasAllocated['discounts'], Decimal.parse('-3.00'));
      expect(breakdown.roundedAdjustment, Decimal.parse('0.01'));
      expect(breakdown.total, Decimal.parse('30.73'));
      expect(breakdown.items, hasLength(1));
      expect(breakdown.items[0], item1);
    });

    test('creates breakdown with multiple items', () {
      final item1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final item2 = ItemContribution(
        itemId: 'item2',
        itemName: 'Fries',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('4.50'),
        assignedShare: Decimal.parse('1'),
      );

      final item3 = ItemContribution(
        itemId: 'item3',
        itemName: 'Soda',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('2.50'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('19.50'),
        extrasAllocated: {},
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('19.50'),
        items: [item1, item2, item3],
      );

      expect(breakdown.items, hasLength(3));
      expect(breakdown.items[0], item1);
      expect(breakdown.items[1], item2);
      expect(breakdown.items[2], item3);
    });

    test('creates breakdown with empty extras map', () {
      final item1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('12.50'),
        extrasAllocated: {},
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('12.50'),
        items: [item1],
      );

      expect(breakdown.extrasAllocated, isEmpty);
    });

    test('creates breakdown with only tax extra', () {
      final item1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('10.00'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('10.00'),
        extrasAllocated: {
          'tax': Decimal.parse('0.89'),
        },
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('10.89'),
        items: [item1],
      );

      expect(breakdown.extrasAllocated, hasLength(1));
      expect(breakdown.extrasAllocated['tax'], Decimal.parse('0.89'));
      expect(breakdown.extrasAllocated.containsKey('tip'), false);
    });

    test('creates breakdown with negative discount', () {
      final item1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Steak',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('30.00'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('30.00'),
        extrasAllocated: {
          'discounts': Decimal.parse('-5.00'),
        },
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('25.00'),
        items: [item1],
      );

      expect(breakdown.extrasAllocated['discounts'], Decimal.parse('-5.00'));
    });

    test('creates breakdown with negative rounding adjustment', () {
      final item1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Item',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('10.00'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('10.00'),
        extrasAllocated: {},
        roundedAdjustment: Decimal.parse('-0.01'),
        total: Decimal.parse('9.99'),
        items: [item1],
      );

      expect(breakdown.roundedAdjustment, Decimal.parse('-0.01'));
    });

    test('creates breakdown with positive rounding adjustment', () {
      final item1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Item',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('10.00'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('10.00'),
        extrasAllocated: {},
        roundedAdjustment: Decimal.parse('0.02'),
        total: Decimal.parse('10.02'),
        items: [item1],
      );

      expect(breakdown.roundedAdjustment, Decimal.parse('0.02'));
    });

    group('real-world scenarios', () {
      test('creates breakdown for simple bill (items + tax + tip)', () {
        final burger = ItemContribution(
          itemId: 'burger',
          itemName: 'Cheeseburger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('15.99'),
          assignedShare: Decimal.parse('1'),
        );

        final fries = ItemContribution(
          itemId: 'fries',
          itemName: 'French Fries',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('4.99'),
          assignedShare: Decimal.parse('1'),
        );

        // Subtotal: $20.98, Tax: $1.87 (8.875%), Tip: $4.57 (20% on post-tax)
        final breakdown = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('20.98'),
          extrasAllocated: {
            'tax': Decimal.parse('1.87'),
            'tip': Decimal.parse('4.57'),
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('27.42'),
          items: [burger, fries],
        );

        expect(breakdown.itemsSubtotal, Decimal.parse('20.98'));
        expect(breakdown.extrasAllocated['tax'], Decimal.parse('1.87'));
        expect(breakdown.extrasAllocated['tip'], Decimal.parse('4.57'));
        expect(breakdown.total, Decimal.parse('27.42'));
      });

      test('creates breakdown for shared items (partial shares)', () {
        final pizza = ItemContribution(
          itemId: 'pizza',
          itemName: 'Large Pizza',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('24.00'),
          assignedShare: Decimal.parse('0.5'),
        );

        final salad = ItemContribution(
          itemId: 'salad',
          itemName: 'Caesar Salad',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('10.00'),
          assignedShare: Decimal.parse('0.333333'),
        );

        // User's share: $12 + $3.33 = $15.33
        final breakdown = ParticipantBreakdown(
          userId: 'user2',
          itemsSubtotal: Decimal.parse('15.33'),
          extrasAllocated: {
            'tax': Decimal.parse('1.36'),
            'tip': Decimal.parse('3.34'),
          },
          roundedAdjustment: Decimal.parse('-0.01'),
          total: Decimal.parse('20.02'),
          items: [pizza, salad],
        );

        expect(breakdown.items[0].assignedShare, Decimal.parse('0.5'));
        expect(breakdown.items[1].assignedShare, Decimal.parse('0.333333'));
      });

      test('creates breakdown with delivery fee', () {
        final item = ItemContribution(
          itemId: 'item1',
          itemName: 'Sandwich',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.00'),
          assignedShare: Decimal.parse('1'),
        );

        final breakdown = ParticipantBreakdown(
          userId: 'user3',
          itemsSubtotal: Decimal.parse('12.00'),
          extrasAllocated: {
            'tax': Decimal.parse('1.07'),
            'fees': Decimal.parse('3.99'), // Delivery fee
            'tip': Decimal.parse('3.41'),
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('20.47'),
          items: [item],
        );

        expect(breakdown.extrasAllocated['fees'], Decimal.parse('3.99'));
      });

      test('creates breakdown with happy hour discount', () {
        final appetizer = ItemContribution(
          itemId: 'appetizer',
          itemName: 'Calamari',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.00'),
          assignedShare: Decimal.parse('1'),
        );

        // Happy hour 50% off: -$6.00
        final breakdown = ParticipantBreakdown(
          userId: 'user4',
          itemsSubtotal: Decimal.parse('12.00'),
          extrasAllocated: {
            'discounts': Decimal.parse('-6.00'),
            'tax': Decimal.parse('0.53'), // Tax on discounted amount
            'tip': Decimal.parse('1.31'), // Tip on post-tax
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('7.84'),
          items: [appetizer],
        );

        expect(breakdown.extrasAllocated['discounts'], Decimal.parse('-6.00'));
      });

      test('creates breakdown with multiple fees and discounts', () {
        final item = ItemContribution(
          itemId: 'item1',
          itemName: 'Meal',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('25.00'),
          assignedShare: Decimal.parse('1'),
        );

        final breakdown = ParticipantBreakdown(
          userId: 'user5',
          itemsSubtotal: Decimal.parse('25.00'),
          extrasAllocated: {
            'discounts': Decimal.parse('-5.00'), // $5 off coupon
            'tax': Decimal.parse('1.78'), // 8.875% on $20
            'fees': Decimal.parse('2.50'), // Service fee
            'tip': Decimal.parse('4.86'), // 20% tip
          },
          roundedAdjustment: Decimal.parse('0.01'),
          total: Decimal.parse('29.15'),
          items: [item],
        );

        expect(breakdown.extrasAllocated, hasLength(4));
      });

      test('creates breakdown with no items (edge case)', () {
        // Edge case: participant didn't order items but shares fees/discounts
        final breakdown = ParticipantBreakdown(
          userId: 'user6',
          itemsSubtotal: Decimal.zero,
          extrasAllocated: {
            'fees': Decimal.parse('2.00'), // Share of delivery fee
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('2.00'),
          items: [],
        );

        expect(breakdown.items, isEmpty);
        expect(breakdown.itemsSubtotal, Decimal.zero);
        expect(breakdown.total, Decimal.parse('2.00'));
      });
    });

    group('audit trail verification', () {
      test('verifies total equals itemsSubtotal + sum of extras + adjustment', () {
        final item = ItemContribution(
          itemId: 'item1',
          itemName: 'Item',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('100.00'),
          assignedShare: Decimal.parse('1'),
        );

        final breakdown = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('100.00'),
          extrasAllocated: {
            'tax': Decimal.parse('8.88'),
            'tip': Decimal.parse('21.78'),
            'fees': Decimal.parse('3.00'),
            'discounts': Decimal.parse('-10.00'),
          },
          roundedAdjustment: Decimal.parse('0.01'),
          total: Decimal.parse('123.67'),
          items: [item],
        );

        // Verify: 100 + 8.88 + 21.78 + 3.00 - 10.00 + 0.01 = 123.67
        final calculatedTotal = breakdown.itemsSubtotal +
            (breakdown.extrasAllocated['tax'] ?? Decimal.zero) +
            (breakdown.extrasAllocated['tip'] ?? Decimal.zero) +
            (breakdown.extrasAllocated['fees'] ?? Decimal.zero) +
            (breakdown.extrasAllocated['discounts'] ?? Decimal.zero) +
            breakdown.roundedAdjustment;

        expect(calculatedTotal, breakdown.total);
      });

      test('verifies extras can be individually traced', () {
        final item = ItemContribution(
          itemId: 'item1',
          itemName: 'Item',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('50.00'),
          assignedShare: Decimal.parse('1'),
        );

        final breakdown = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('50.00'),
          extrasAllocated: {
            'tax': Decimal.parse('4.44'),
            'tip': Decimal.parse('10.89'),
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('65.33'),
          items: [item],
        );

        // Verify each extra can be accessed
        expect(breakdown.extrasAllocated.containsKey('tax'), true);
        expect(breakdown.extrasAllocated.containsKey('tip'), true);
        expect(breakdown.extrasAllocated.containsKey('fees'), false);
        expect(breakdown.extrasAllocated.containsKey('discounts'), false);

        expect(breakdown.extrasAllocated['tax'], Decimal.parse('4.44'));
        expect(breakdown.extrasAllocated['tip'], Decimal.parse('10.89'));
      });
    });

    test('supports equality comparison', () {
      final item = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown1 = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('12.50'),
        extrasAllocated: {
          'tax': Decimal.parse('1.11'),
        },
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('13.61'),
        items: [item],
      );

      final breakdown2 = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('12.50'),
        extrasAllocated: {
          'tax': Decimal.parse('1.11'),
        },
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('13.61'),
        items: [item],
      );

      expect(breakdown1, equals(breakdown2));
    });

    test('distinguishes different participant breakdowns', () {
      final item = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final breakdown1 = ParticipantBreakdown(
        userId: 'user1',
        itemsSubtotal: Decimal.parse('12.50'),
        extrasAllocated: {},
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('12.50'),
        items: [item],
      );

      final breakdown2 = ParticipantBreakdown(
        userId: 'user2',
        itemsSubtotal: Decimal.parse('12.50'),
        extrasAllocated: {},
        roundedAdjustment: Decimal.zero,
        total: Decimal.parse('12.50'),
        items: [item],
      );

      expect(breakdown1, isNot(equals(breakdown2)));
    });
  });
}
