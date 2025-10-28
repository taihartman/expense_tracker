import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/line_item.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_assignment.dart';
import 'package:expense_tracker/features/expenses/domain/models/assignment_mode.dart';

void main() {
  group('LineItem', () {
    final validAssignment = ItemAssignment(
      mode: AssignmentMode.even,
      users: ['user1', 'user2'],
    );

    test('creates valid line item', () {
      final lineItem = LineItem(
        id: 'item1',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        taxable: true,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      expect(lineItem.id, 'item1');
      expect(lineItem.name, 'Burger');
      expect(lineItem.quantity, Decimal.parse('2'));
      expect(lineItem.unitPrice, Decimal.parse('12.50'));
      expect(lineItem.taxable, true);
      expect(lineItem.serviceChargeable, true);
      expect(lineItem.assignment, validAssignment);
    });

    test('creates line item with tax-exempt flag', () {
      final lineItem = LineItem(
        id: 'item2',
        name: 'Salad',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('8.00'),
        taxable: false,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      expect(lineItem.taxable, false);
    });

    test('creates line item with no service charge flag', () {
      final lineItem = LineItem(
        id: 'item3',
        name: 'Drink',
        quantity: Decimal.parse('3'),
        unitPrice: Decimal.parse('3.50'),
        taxable: true,
        serviceChargeable: false,
        assignment: validAssignment,
      );

      expect(lineItem.serviceChargeable, false);
    });

    group('computed itemTotal', () {
      test('calculates itemTotal = quantity * unitPrice', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Pizza',
          quantity: Decimal.parse('2'),
          unitPrice: Decimal.parse('15.99'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        expect(lineItem.itemTotal, Decimal.parse('31.98'));
      });

      test('calculates itemTotal with decimal quantity', () {
        final lineItem = LineItem(
          id: 'item2',
          name: 'Cheese by pound',
          quantity: Decimal.parse('0.5'),
          unitPrice: Decimal.parse('20.00'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        expect(lineItem.itemTotal, Decimal.parse('10.00'));
      });

      test('calculates itemTotal with quantity = 1', () {
        final lineItem = LineItem(
          id: 'item3',
          name: 'Steak',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('29.99'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        expect(lineItem.itemTotal, Decimal.parse('29.99'));
      });

      test('calculates itemTotal with zero unit price', () {
        final lineItem = LineItem(
          id: 'item4',
          name: 'Free item',
          quantity: Decimal.parse('5'),
          unitPrice: Decimal.parse('0'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        expect(lineItem.itemTotal, Decimal.zero);
      });

      test('calculates itemTotal with high precision', () {
        final lineItem = LineItem(
          id: 'item5',
          name: 'Gas',
          quantity: Decimal.parse('10.543'),
          unitPrice: Decimal.parse('3.789'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        expect(lineItem.itemTotal, Decimal.parse('39.947727'));
      });
    });

    group('validation', () {
      test('validates name is not empty', () {
        expect(
          () => LineItem(
            id: 'item1',
            name: '',
            quantity: Decimal.parse('1'),
            unitPrice: Decimal.parse('10.00'),
            taxable: true,
            serviceChargeable: true,
            assignment: validAssignment,
          ),
          throwsArgumentError,
        );
      });

      test('validates name is not whitespace only', () {
        expect(
          () => LineItem(
            id: 'item1',
            name: '   ',
            quantity: Decimal.parse('1'),
            unitPrice: Decimal.parse('10.00'),
            taxable: true,
            serviceChargeable: true,
            assignment: validAssignment,
          ),
          throwsArgumentError,
        );
      });

      test('validates quantity is positive', () {
        expect(
          () => LineItem(
            id: 'item1',
            name: 'Item',
            quantity: Decimal.parse('0'),
            unitPrice: Decimal.parse('10.00'),
            taxable: true,
            serviceChargeable: true,
            assignment: validAssignment,
          ),
          throwsArgumentError,
        );

        expect(
          () => LineItem(
            id: 'item2',
            name: 'Item',
            quantity: Decimal.parse('-1'),
            unitPrice: Decimal.parse('10.00'),
            taxable: true,
            serviceChargeable: true,
            assignment: validAssignment,
          ),
          throwsArgumentError,
        );
      });

      test('validates unitPrice is non-negative', () {
        // Zero is allowed (free items)
        expect(
          () => LineItem(
            id: 'item1',
            name: 'Free item',
            quantity: Decimal.parse('1'),
            unitPrice: Decimal.parse('0'),
            taxable: true,
            serviceChargeable: true,
            assignment: validAssignment,
          ),
          returnsNormally,
        );

        // Negative is not allowed
        expect(
          () => LineItem(
            id: 'item2',
            name: 'Item',
            quantity: Decimal.parse('1'),
            unitPrice: Decimal.parse('-5.00'),
            taxable: true,
            serviceChargeable: true,
            assignment: validAssignment,
          ),
          throwsArgumentError,
        );
      });

      test('validates assignment is required', () {
        expect(
          () => LineItem(
            id: 'item1',
            name: 'Item',
            quantity: Decimal.parse('1'),
            unitPrice: Decimal.parse('10.00'),
            taxable: true,
            serviceChargeable: true,
            assignment: null as dynamic,
          ),
          throwsA(anything), // Will throw either ArgumentError or TypeError
        );
      });

      test('validates id is not empty', () {
        expect(
          () => LineItem(
            id: '',
            name: 'Item',
            quantity: Decimal.parse('1'),
            unitPrice: Decimal.parse('10.00'),
            taxable: true,
            serviceChargeable: true,
            assignment: validAssignment,
          ),
          throwsArgumentError,
        );
      });
    });

    test('supports equality comparison', () {
      final lineItem1 = LineItem(
        id: 'item1',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        taxable: true,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      final lineItem2 = LineItem(
        id: 'item1',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        taxable: true,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      expect(lineItem1, equals(lineItem2));
    });

    test('distinguishes different line items', () {
      final lineItem1 = LineItem(
        id: 'item1',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        taxable: true,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      final lineItem2 = LineItem(
        id: 'item2',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        taxable: true,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      expect(lineItem1, isNot(equals(lineItem2)));
    });

    test('supports copyWith for all properties', () {
      final assignment2 = ItemAssignment(
        mode: AssignmentMode.custom,
        users: ['user1', 'user2'],
        shares: {'user1': Decimal.parse('0.7'), 'user2': Decimal.parse('0.3')},
      );

      final lineItem = LineItem(
        id: 'item1',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        taxable: true,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      final updated = lineItem.copyWith(
        name: 'Cheeseburger',
        quantity: Decimal.parse('3'),
        unitPrice: Decimal.parse('13.50'),
        taxable: false,
        serviceChargeable: false,
        assignment: assignment2,
      );

      expect(updated.id, 'item1'); // ID should not change
      expect(updated.name, 'Cheeseburger');
      expect(updated.quantity, Decimal.parse('3'));
      expect(updated.unitPrice, Decimal.parse('13.50'));
      expect(updated.taxable, false);
      expect(updated.serviceChargeable, false);
      expect(updated.assignment, assignment2);
    });

    test('supports copyWith with partial updates', () {
      final lineItem = LineItem(
        id: 'item1',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('12.50'),
        taxable: true,
        serviceChargeable: true,
        assignment: validAssignment,
      );

      final updated = lineItem.copyWith(quantity: Decimal.parse('5'));

      expect(updated.id, 'item1');
      expect(updated.name, 'Burger');
      expect(updated.quantity, Decimal.parse('5'));
      expect(updated.unitPrice, Decimal.parse('12.50'));
      expect(updated.taxable, true);
      expect(updated.serviceChargeable, true);
      expect(updated.assignment, validAssignment);
      // itemTotal should recalculate
      expect(updated.itemTotal, Decimal.parse('62.50'));
    });
  });
}
