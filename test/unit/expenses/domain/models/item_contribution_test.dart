import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_contribution.dart';

void main() {
  group('ItemContribution', () {
    test('creates valid item contribution', () {
      final contribution = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution.itemId, 'item1');
      expect(contribution.itemName, 'Burger');
      expect(contribution.quantity, Decimal.parse('2'));
      expect(contribution.unitPrice, Decimal.parse('12.50'));
      expect(contribution.assignedShare, Decimal.parse('1'));
    });

    test('creates item contribution with partial share', () {
      final contribution = ItemContribution(
        itemId: 'item2',
        itemName: 'Pizza',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('20.00'),
        assignedShare: Decimal.parse('0.5'),
      );

      expect(contribution.assignedShare, Decimal.parse('0.5'));
    });

    test('creates item contribution with multiple quantity', () {
      final contribution = ItemContribution(
        itemId: 'item3',
        itemName: 'Beer',
        quantity: Decimal.parse('3'),
        unitPrice: Decimal.parse('5.50'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution.quantity, Decimal.parse('3'));
    });

    test('creates item contribution with decimal quantity', () {
      final contribution = ItemContribution(
        itemId: 'item4',
        itemName: 'Cheese by pound',
        quantity: Decimal.parse('0.75'),
        unitPrice: Decimal.parse('15.00'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution.quantity, Decimal.parse('0.75'));
    });

    test('creates item contribution with zero unit price', () {
      final contribution = ItemContribution(
        itemId: 'item5',
        itemName: 'Free appetizer',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('0'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution.unitPrice, Decimal.zero);
    });

    test('creates item contribution with weighted share', () {
      final contribution = ItemContribution(
        itemId: 'item6',
        itemName: 'Shared salad',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('12.00'),
        assignedShare: Decimal.parse('0.333333'),
      );

      expect(contribution.assignedShare, Decimal.parse('0.333333'));
    });

    test('creates item contribution with high precision share', () {
      final contribution = ItemContribution(
        itemId: 'item7',
        itemName: 'Shared item',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('10.00'),
        assignedShare: Decimal.parse('0.142857142857'),
      );

      expect(contribution.assignedShare, Decimal.parse('0.142857142857'));
    });

    group('real-world scenarios', () {
      test('creates contribution for fully assigned item', () {
        // Person ordered 2 burgers, they pay for all of it
        final contribution = ItemContribution(
          itemId: 'burger_item',
          itemName: 'Cheeseburger',
          quantity: Decimal.parse('2'),
          unitPrice: Decimal.parse('15.99'),
          assignedShare: Decimal.parse('1'),
        );

        expect(contribution.assignedShare, Decimal.parse('1'));
      });

      test('creates contribution for evenly split item (2 people)', () {
        // Pizza split evenly between 2 people
        final contribution = ItemContribution(
          itemId: 'pizza_item',
          itemName: 'Large Pizza',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('22.00'),
          assignedShare: Decimal.parse('0.5'),
        );

        expect(contribution.assignedShare, Decimal.parse('0.5'));
      });

      test('creates contribution for evenly split item (3 people)', () {
        // Appetizer split evenly among 3 people
        final contribution = ItemContribution(
          itemId: 'appetizer_item',
          itemName: 'Calamari',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.99'),
          assignedShare: Decimal.parse('0.333333'),
        );

        expect(contribution.assignedShare, Decimal.parse('0.333333'));
      });

      test('creates contribution for weighted split item', () {
        // Bottle of wine split 70/30
        final contribution = ItemContribution(
          itemId: 'wine_item',
          itemName: 'Bottle of Wine',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('45.00'),
          assignedShare: Decimal.parse('0.7'),
        );

        expect(contribution.assignedShare, Decimal.parse('0.7'));
      });

      test('creates contribution for quantity-based item', () {
        // Person ordered 5 wings from a shared platter
        final contribution = ItemContribution(
          itemId: 'wings_item',
          itemName: 'Chicken Wings',
          quantity: Decimal.parse('5'),
          unitPrice: Decimal.parse('1.50'),
          assignedShare: Decimal.parse('1'),
        );

        expect(contribution.quantity, Decimal.parse('5'));
        expect(contribution.unitPrice, Decimal.parse('1.50'));
      });
    });

    test('supports equality comparison', () {
      final contribution1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final contribution2 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution1, equals(contribution2));
    });

    test('distinguishes different item contributions by id', () {
      final contribution1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final contribution2 = ItemContribution(
        itemId: 'item2',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution1, isNot(equals(contribution2)));
    });

    test('distinguishes different item contributions by name', () {
      final contribution1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final contribution2 = ItemContribution(
        itemId: 'item1',
        itemName: 'Pizza',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution1, isNot(equals(contribution2)));
    });

    test('distinguishes different item contributions by quantity', () {
      final contribution1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final contribution2 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('3'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution1, isNot(equals(contribution2)));
    });

    test('distinguishes different item contributions by unit price', () {
      final contribution1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final contribution2 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('15.00'),
        assignedShare: Decimal.parse('1'),
      );

      expect(contribution1, isNot(equals(contribution2)));
    });

    test('distinguishes different item contributions by assigned share', () {
      final contribution1 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('1'),
      );

      final contribution2 = ItemContribution(
        itemId: 'item1',
        itemName: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        assignedShare: Decimal.parse('0.5'),
      );

      expect(contribution1, isNot(equals(contribution2)));
    });
  });
}
