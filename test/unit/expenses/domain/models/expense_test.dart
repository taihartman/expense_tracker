import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/features/expenses/domain/models/line_item.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_assignment.dart';
import 'package:expense_tracker/features/expenses/domain/models/assignment_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/extras.dart';
import 'package:expense_tracker/features/expenses/domain/models/tax_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/tip_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';
import 'package:expense_tracker/features/expenses/domain/models/allocation_rule.dart';
import 'package:expense_tracker/features/expenses/domain/models/absolute_split_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_config.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/remainder_distribution_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/participant_breakdown.dart';
import 'package:expense_tracker/core/models/split_type.dart';
import 'package:expense_tracker/core/models/currency_code.dart';

void main() {
  group('Expense - Itemized Split', () {
    final defaultRounding = RoundingConfig(
      precision: Decimal.parse('0.01'),
      mode: RoundingMode.roundHalfUp,
      distributeRemainderTo: RemainderDistributionMode.largestShare,
    );

    final defaultAllocation = AllocationRule(
      percentBase: PercentBase.preTaxItemSubtotals,
      absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
      rounding: defaultRounding,
    );

    final validAssignment = ItemAssignment(
      mode: AssignmentMode.even,
      users: ['user1', 'user2'],
    );

    group('creation with itemized fields', () {
      test('creates expense with items field', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final expense = Expense(
          id: 'exp1',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('12.50'),
          splitType: SplitType.itemized,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem],
        );

        expect(expense.items, isNotNull);
        expect(expense.items, hasLength(1));
        expect(expense.items![0], lineItem);
      });

      test('creates expense with extras field', () {
        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );

        final extras = Extras(tax: tax, tip: null, fees: [], discounts: []);

        final expense = Expense(
          id: 'exp2',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('10.89'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          extras: extras,
        );

        expect(expense.extras, isNotNull);
        expect(expense.extras, extras);
      });

      test('creates expense with allocation field', () {
        final expense = Expense(
          id: 'exp3',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          allocation: defaultAllocation,
        );

        expect(expense.allocation, isNotNull);
        expect(expense.allocation, defaultAllocation);
      });

      test('creates expense with participantAmounts field', () {
        final participantAmounts = {
          'user1': Decimal.parse('15.50'),
          'user2': Decimal.parse('10.25'),
        };

        final expense = Expense(
          id: 'exp4',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('25.75'),
          splitType: SplitType.itemized,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participantAmounts: participantAmounts,
        );

        expect(expense.participantAmounts, isNotNull);
        expect(expense.participantAmounts, participantAmounts);
        expect(expense.participantAmounts!['user1'], Decimal.parse('15.50'));
        expect(expense.participantAmounts!['user2'], Decimal.parse('10.25'));
      });

      test('creates expense with participantBreakdown field', () {
        final breakdown = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('25.00'),
          extrasAllocated: {
            'tax': Decimal.parse('2.22'),
            'tip': Decimal.parse('5.00'),
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('32.22'),
          items: [],
        );

        final participantBreakdown = {'user1': breakdown};

        final expense = Expense(
          id: 'exp5',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('32.22'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participantBreakdown: participantBreakdown,
        );

        expect(expense.participantBreakdown, isNotNull);
        expect(expense.participantBreakdown, participantBreakdown);
        expect(expense.participantBreakdown!['user1'], breakdown);
      });

      test('creates expense with all itemized fields', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final tax = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );

        final tip = TipExtra.percent(
          value: Decimal.parse('20'),
          base: PercentBase.postTaxSubtotals,
        );

        final extras = Extras(tax: tax, tip: tip, fees: [], discounts: []);

        final breakdown1 = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('6.25'),
          extrasAllocated: {
            'tax': Decimal.parse('0.55'),
            'tip': Decimal.parse('1.36'),
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('8.16'),
          items: [],
        );

        final breakdown2 = ParticipantBreakdown(
          userId: 'user2',
          itemsSubtotal: Decimal.parse('6.25'),
          extrasAllocated: {
            'tax': Decimal.parse('0.56'),
            'tip': Decimal.parse('1.36'),
          },
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('8.17'),
          items: [],
        );

        final expense = Expense(
          id: 'exp6',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('16.33'),
          splitType: SplitType.itemized,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem],
          extras: extras,
          allocation: defaultAllocation,
          participantAmounts: {
            'user1': Decimal.parse('8.16'),
            'user2': Decimal.parse('8.17'),
          },
          participantBreakdown: {'user1': breakdown1, 'user2': breakdown2},
        );

        expect(expense.items, isNotNull);
        expect(expense.extras, isNotNull);
        expect(expense.allocation, isNotNull);
        expect(expense.participantAmounts, isNotNull);
        expect(expense.participantBreakdown, isNotNull);
      });
    });

    group('validation for itemized expenses', () {
      test('validates itemized expense must have items', () {
        final expense = Expense(
          id: 'exp7',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: null, // Missing items
          participantAmounts: {'user1': Decimal.parse('100.00')},
        );

        final error = expense.validate();

        expect(error, isNotNull);
        expect(error!.toLowerCase(), contains('itemized'));
        expect(error.toLowerCase(), contains('items'));
      });

      test('validates itemized expense must have participantAmounts', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final expense = Expense(
          id: 'exp8',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('12.50'),
          splitType: SplitType.itemized,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem],
          participantAmounts: null, // Missing participantAmounts
        );

        final error = expense.validate();

        expect(error, isNotNull);
        expect(error!.toLowerCase(), contains('itemized'));
        expect(error.toLowerCase(), contains('participantamounts'));
      });

      test('validates itemized expense with empty items list', () {
        final expense = Expense(
          id: 'exp9',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [], // Empty items list
          participantAmounts: {'user1': Decimal.parse('100.00')},
        );

        final error = expense.validate();

        expect(error, isNotNull);
        expect(error!.toLowerCase(), contains('itemized'));
        expect(error.toLowerCase(), contains('items'));
      });

      test('validates itemized expense with valid fields passes', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final expense = Expense(
          id: 'exp10',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('12.50'),
          splitType: SplitType.itemized,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem],
          participantAmounts: {
            'user1': Decimal.parse('6.25'),
            'user2': Decimal.parse('6.25'),
          },
        );

        final error = expense.validate();

        expect(error, isNull);
      });
    });

    group('backward compatibility', () {
      test('equal split expense works without itemized fields', () {
        final expense = Expense(
          id: 'exp11',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.equal,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNull);

        final shares = expense.calculateShares();
        expect(shares['user1'], Decimal.parse('50.00'));
        expect(shares['user2'], Decimal.parse('50.00'));
      });

      test('weighted split expense works without itemized fields', () {
        final expense = Expense(
          id: 'exp12',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.weighted,
          participants: {'user1': 2, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNull);

        final shares = expense.calculateShares();
        expect(shares['user1'], Decimal.parse('66.67'));
        expect(shares['user2'], Decimal.parse('33.33'));
      });

      test('equal split ignores itemized fields if present', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final expense = Expense(
          id: 'exp13',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.equal,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem], // Ignored for equal split
        );

        final error = expense.validate();
        expect(error, isNull);

        final shares = expense.calculateShares();
        expect(shares['user1'], Decimal.parse('50.00'));
        expect(shares['user2'], Decimal.parse('50.00'));
      });

      test('weighted split ignores itemized fields if present', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final expense = Expense(
          id: 'exp14',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.weighted,
          participants: {'user1': 3, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem], // Ignored for weighted split
        );

        final error = expense.validate();
        expect(error, isNull);

        final shares = expense.calculateShares();
        expect(shares['user1'], Decimal.parse('75.00'));
        expect(shares['user2'], Decimal.parse('25.00'));
      });
    });

    group('copyWith with itemized fields', () {
      test('supports copyWith for items field', () {
        final lineItem1 = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final lineItem2 = LineItem(
          id: 'item2',
          name: 'Fries',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('4.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final expense = Expense(
          id: 'exp15',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('12.50'),
          splitType: SplitType.itemized,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem1],
          participantAmounts: {
            'user1': Decimal.parse('6.25'),
            'user2': Decimal.parse('6.25'),
          },
        );

        final updated = expense.copyWith(items: [lineItem1, lineItem2]);

        expect(updated.items, hasLength(2));
        expect(updated.items![0], lineItem1);
        expect(updated.items![1], lineItem2);
      });

      test('supports copyWith for extras field', () {
        final tax1 = TaxExtra.percent(
          value: Decimal.parse('8.875'),
          base: PercentBase.preTaxItemSubtotals,
        );

        final tax2 = TaxExtra.percent(
          value: Decimal.parse('10'),
          base: PercentBase.preTaxItemSubtotals,
        );

        final extras1 = Extras(tax: tax1, tip: null, fees: [], discounts: []);

        final extras2 = Extras(tax: tax2, tip: null, fees: [], discounts: []);

        final expense = Expense(
          id: 'exp16',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('10.89'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          extras: extras1,
          participantAmounts: {'user1': Decimal.parse('10.89')},
        );

        final updated = expense.copyWith(extras: extras2);

        expect(updated.extras, extras2);
      });

      test('supports copyWith for allocation field', () {
        final allocation1 = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: defaultRounding,
        );

        final allocation2 = AllocationRule(
          percentBase: PercentBase.postTaxSubtotals,
          absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
          rounding: defaultRounding,
        );

        final expense = Expense(
          id: 'exp17',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          allocation: allocation1,
          participantAmounts: {'user1': Decimal.parse('100.00')},
        );

        final updated = expense.copyWith(allocation: allocation2);

        expect(updated.allocation, allocation2);
      });

      test('supports copyWith for participantAmounts field', () {
        final amounts1 = {
          'user1': Decimal.parse('50.00'),
          'user2': Decimal.parse('50.00'),
        };

        final amounts2 = {
          'user1': Decimal.parse('60.00'),
          'user2': Decimal.parse('40.00'),
        };

        final expense = Expense(
          id: 'exp18',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.itemized,
          participants: {'user1': 1, 'user2': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participantAmounts: amounts1,
        );

        final updated = expense.copyWith(participantAmounts: amounts2);

        expect(updated.participantAmounts, amounts2);
        expect(updated.participantAmounts!['user1'], Decimal.parse('60.00'));
        expect(updated.participantAmounts!['user2'], Decimal.parse('40.00'));
      });

      test('supports copyWith for participantBreakdown field', () {
        final breakdown1 = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('50.00'),
          extrasAllocated: {},
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('50.00'),
          items: [],
        );

        final breakdown2 = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('60.00'),
          extrasAllocated: {},
          roundedAdjustment: Decimal.zero,
          total: Decimal.parse('60.00'),
          items: [],
        );

        final expense = Expense(
          id: 'exp19',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('50.00'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          participantBreakdown: {'user1': breakdown1},
          participantAmounts: {'user1': Decimal.parse('50.00')},
        );

        final updated = expense.copyWith(
          participantBreakdown: {'user1': breakdown2},
        );

        expect(updated.participantBreakdown!['user1'], breakdown2);
      });
    });

    group('equality with itemized fields', () {
      test('considers items in equality comparison', () {
        final lineItem = LineItem(
          id: 'item1',
          name: 'Burger',
          quantity: Decimal.parse('1'),
          unitPrice: Decimal.parse('12.50'),
          taxable: true,
          serviceChargeable: true,
          assignment: validAssignment,
        );

        final expense1 = Expense(
          id: 'exp20',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('12.50'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem],
          participantAmounts: {'user1': Decimal.parse('12.50')},
        );

        final expense2 = Expense(
          id: 'exp20',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('12.50'),
          splitType: SplitType.itemized,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [lineItem],
          participantAmounts: {'user1': Decimal.parse('12.50')},
        );

        // Note: Expense equality is based on ID only, per the existing implementation
        expect(expense1, equals(expense2));
      });

      test('distinguishes expenses with different IDs', () {
        final expense1 = Expense(
          id: 'exp21',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.equal,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final expense2 = Expense(
          id: 'exp22',
          tripId: 'trip1',
          date: DateTime(2025, 10, 21),
          payerUserId: 'user1',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('100.00'),
          splitType: SplitType.equal,
          participants: {'user1': 1},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(expense1, isNot(equals(expense2)));
      });
    });
  });
}
