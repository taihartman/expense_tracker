import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/features/expenses/domain/models/line_item.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_assignment.dart';
import 'package:expense_tracker/features/expenses/domain/models/extras.dart';
import 'package:expense_tracker/features/expenses/domain/models/tax_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/tip_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/fee_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/discount_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/allocation_rule.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_config.dart';
import 'package:expense_tracker/features/expenses/domain/models/participant_breakdown.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_contribution.dart';
import 'package:expense_tracker/core/models/currency_code.dart';
import 'package:expense_tracker/core/models/split_type.dart';
import 'package:expense_tracker/features/expenses/domain/models/assignment_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';
import 'package:expense_tracker/features/expenses/domain/models/absolute_split_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/remainder_distribution_mode.dart';

void main() {
  group('ExpenseModel - Itemized Extensions', () {
    late DateTime testDate;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 18, 30);
      testCreatedAt = DateTime(2024, 1, 15, 18, 35);
      testUpdatedAt = DateTime(2024, 1, 15, 18, 35);
    });

    group('Full Itemized Expense - Serialization', () {
      test(
        'should serialize and deserialize full itemized expense with all fields',
        () {
          // Arrange - Create a complete itemized expense
          final items = [
            LineItem(
              id: 'item1',
              name: 'Pizza',
              quantity: Decimal.fromInt(2),
              unitPrice: Decimal.parse('15.99'),
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
              quantity: Decimal.fromInt(1),
              unitPrice: Decimal.parse('8.50'),
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
            tax: TaxExtra.percent(
              value: Decimal.parse('8.5'),
              base: PercentBase.preTaxItemSubtotals,
            ),
            tip: TipExtra.amount(value: Decimal.parse('5.00')),
            fees: [
              FeeExtra(
                id: 'fee1',
                name: 'Service Charge',
                type: 'percent',
                value: Decimal.parse('10'),
                base: PercentBase.preTaxItemSubtotals,
              ),
            ],
            discounts: [
              DiscountExtra(
                id: 'disc1',
                name: 'Promo Code',
                type: 'amount',
                value: Decimal.parse('3.00'),
              ),
            ],
          );

          final allocation = AllocationRule(
            percentBase: PercentBase.preTaxItemSubtotals,
            absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
            rounding: RoundingConfig(
              precision: Decimal.parse('0.01'),
              mode: RoundingMode.roundHalfUp,
              distributeRemainderTo: RemainderDistributionMode.largestShare,
            ),
          );

          final participantBreakdown = {
            'alice': ParticipantBreakdown(
              userId: 'alice',
              itemsSubtotal: Decimal.parse('20.49'),
              extrasAllocated: {
                'tax': Decimal.parse('1.74'),
                'tip': Decimal.parse('2.55'),
              },
              roundedAdjustment: Decimal.parse('0.01'),
              total: Decimal.parse('24.79'),
              items: [
                ItemContribution(
                  itemId: 'item1',
                  itemName: 'Pizza',
                  quantity: Decimal.fromInt(2),
                  unitPrice: Decimal.parse('15.99'),
                  assignedShare: Decimal.parse('0.5'),
                ),
              ],
            ),
            'bob': ParticipantBreakdown(
              userId: 'bob',
              itemsSubtotal: Decimal.parse('18.54'),
              extrasAllocated: {
                'tax': Decimal.parse('1.58'),
                'tip': Decimal.parse('2.31'),
              },
              roundedAdjustment: Decimal.zero,
              total: Decimal.parse('22.43'),
              items: [
                ItemContribution(
                  itemId: 'item1',
                  itemName: 'Pizza',
                  quantity: Decimal.fromInt(2),
                  unitPrice: Decimal.parse('15.99'),
                  assignedShare: Decimal.parse('0.5'),
                ),
              ],
            ),
          };

          final expense = Expense(
            id: 'exp1',
            tripId: 'trip1',
            date: testDate,
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('47.22'),
            description: 'Dinner at restaurant',
            categoryId: 'food',
            splitType: SplitType.itemized,
            participants: {'alice': 1, 'bob': 1},
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
            // Itemized fields
            items: items,
            extras: extras,
            allocation: allocation,
            participantAmounts: {
              'alice': Decimal.parse('24.79'),
              'bob': Decimal.parse('22.43'),
            },
            participantBreakdown: participantBreakdown,
          );

          // Act - Serialize to JSON
          final json = ExpenseModel.toJson(expense);

          // Assert - Check JSON structure
          expect(json['tripId'], 'trip1');
          expect(json['amount'], '47.22');
          expect(json['splitType'], 'itemized');
          expect(json['items'], isA<List>());
          expect(json['items'], hasLength(2));
          expect(json['extras'], isA<Map>());
          expect(json['allocation'], isA<Map>());
          expect(json['participantAmounts'], isA<Map>());
          expect(json['participantAmounts']['alice'], '24.79');
          expect(json['participantBreakdown'], isA<Map>());
          expect(json['participantBreakdown']['alice'], isA<Map>());

          // Act - Create mock Firestore document and deserialize
          final mockDoc = _MockDocumentSnapshot('exp1', json);
          final deserialized = ExpenseModel.fromFirestore(mockDoc);

          // Assert - Verify deserialized expense matches original
          expect(deserialized.id, expense.id);
          expect(deserialized.tripId, expense.tripId);
          expect(deserialized.amount, expense.amount);
          expect(deserialized.splitType, SplitType.itemized);
          expect(deserialized.items, isNotNull);
          expect(deserialized.items!.length, 2);
          expect(deserialized.items![0].name, 'Pizza');
          expect(deserialized.items![0].quantity, Decimal.fromInt(2));
          expect(deserialized.items![0].unitPrice, Decimal.parse('15.99'));
          expect(deserialized.extras, isNotNull);
          expect(deserialized.extras!.tax, isNotNull);
          expect(deserialized.extras!.tip, isNotNull);
          expect(deserialized.allocation, isNotNull);
          expect(deserialized.participantAmounts, isNotNull);
          expect(
            deserialized.participantAmounts!['alice'],
            Decimal.parse('24.79'),
          );
          expect(deserialized.participantBreakdown, isNotNull);
          expect(deserialized.participantBreakdown!['alice'], isNotNull);
        },
      );
    });

    group('Backward Compatibility', () {
      test('should deserialize old expense without itemized fields', () {
        // Arrange - Old expense JSON without itemized fields
        final json = <String, dynamic>{
          'tripId': 'trip1',
          'date': Timestamp.fromDate(testDate),
          'payerUserId': 'alice',
          'currency': 'USD',
          'amount': '50.00',
          'description': 'Old expense',
          'categoryId': 'food',
          'splitType': 'equal',
          'participants': {'alice': 1, 'bob': 1},
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'updatedAt': Timestamp.fromDate(testUpdatedAt),
          // NO itemized fields
        };

        // Act - Deserialize
        final mockDoc = _MockDocumentSnapshot('exp1', json);
        final expense = ExpenseModel.fromFirestore(mockDoc);

        // Assert - All itemized fields should be null
        expect(expense.id, 'exp1');
        expect(expense.tripId, 'trip1');
        expect(expense.amount, Decimal.parse('50.00'));
        expect(expense.splitType, SplitType.equal);
        expect(expense.items, isNull);
        expect(expense.extras, isNull);
        expect(expense.allocation, isNull);
        expect(expense.participantAmounts, isNull);
        expect(expense.participantBreakdown, isNull);
      });

      test('should handle null itemized fields in Firestore document', () {
        // Arrange - Document with explicit null values
        final json = <String, dynamic>{
          'tripId': 'trip1',
          'date': Timestamp.fromDate(testDate),
          'payerUserId': 'alice',
          'currency': 'USD',
          'amount': '50.00',
          'description': 'Expense with nulls',
          'categoryId': 'food',
          'splitType': 'weighted',
          'participants': {'alice': 2, 'bob': 1},
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'updatedAt': Timestamp.fromDate(testUpdatedAt),
          // Explicit nulls
          'items': null,
          'extras': null,
          'allocation': null,
          'participantAmounts': null,
          'participantBreakdown': null,
        };

        // Act
        final mockDoc = _MockDocumentSnapshot('exp1', json);
        final expense = ExpenseModel.fromFirestore(mockDoc);

        // Assert
        expect(expense.items, isNull);
        expect(expense.extras, isNull);
        expect(expense.allocation, isNull);
        expect(expense.participantAmounts, isNull);
        expect(expense.participantBreakdown, isNull);
      });
    });

    group('Partial Itemized Fields', () {
      test('should handle expense with items but no extras', () {
        // Arrange
        final items = [
          LineItem(
            id: 'item1',
            name: 'Coffee',
            quantity: Decimal.fromInt(1),
            unitPrice: Decimal.parse('3.50'),
            taxable: false,
            serviceChargeable: false,
            assignment: const ItemAssignment(
              mode: AssignmentMode.even,
              users: ['alice'],
            ),
          ),
        ];

        final expense = Expense(
          id: 'exp1',
          tripId: 'trip1',
          date: testDate,
          payerUserId: 'alice',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('3.50'),
          description: 'Simple coffee',
          categoryId: 'food',
          splitType: SplitType.itemized,
          participants: {'alice': 1},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          items: items, // Only items, no extras/allocation
        );

        // Act
        final json = ExpenseModel.toJson(expense);
        final mockDoc = _MockDocumentSnapshot('exp1', json);
        final deserialized = ExpenseModel.fromFirestore(mockDoc);

        // Assert
        expect(deserialized.items, isNotNull);
        expect(deserialized.items!.length, 1);
        expect(deserialized.extras, isNull);
        expect(deserialized.allocation, isNull);
        expect(deserialized.participantAmounts, isNull);
        expect(deserialized.participantBreakdown, isNull);
      });

      test('should handle expense with items and extras but no breakdown', () {
        // Arrange
        final expense = Expense(
          id: 'exp1',
          tripId: 'trip1',
          date: testDate,
          payerUserId: 'alice',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('10.00'),
          description: 'Partial itemized',
          categoryId: 'food',
          splitType: SplitType.itemized,
          participants: {'alice': 1, 'bob': 1},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          items: [
            LineItem(
              id: 'item1',
              name: 'Item',
              quantity: Decimal.fromInt(1),
              unitPrice: Decimal.parse('10.00'),
              taxable: false,
              serviceChargeable: false,
              assignment: const ItemAssignment(
                mode: AssignmentMode.even,
                users: ['alice', 'bob'],
              ),
            ),
          ],
          extras: Extras(
            tax: TaxExtra.percent(
              value: Decimal.parse('8'),
              base: PercentBase.preTaxItemSubtotals,
            ),
            tip: null,
            fees: const [],
            discounts: const [],
          ),
          allocation: AllocationRule(
            percentBase: PercentBase.preTaxItemSubtotals,
            absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
            rounding: RoundingConfig(
              precision: Decimal.parse('0.01'),
              mode: RoundingMode.roundHalfUp,
              distributeRemainderTo: RemainderDistributionMode.largestShare,
            ),
          ),
          // No participantAmounts or participantBreakdown
        );

        // Act
        final json = ExpenseModel.toJson(expense);
        final mockDoc = _MockDocumentSnapshot('exp1', json);
        final deserialized = ExpenseModel.fromFirestore(mockDoc);

        // Assert
        expect(deserialized.items, isNotNull);
        expect(deserialized.extras, isNotNull);
        expect(deserialized.allocation, isNotNull);
        expect(deserialized.participantAmounts, isNull);
        expect(deserialized.participantBreakdown, isNull);
      });
    });

    group('Decimal Precision', () {
      test(
        'should preserve decimal precision through serialization roundtrip',
        () {
          // Arrange - Use precise decimal values
          final expense = Expense(
            id: 'exp1',
            tripId: 'trip1',
            date: testDate,
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('33.333333'),
            description: 'Precision test',
            categoryId: 'test',
            splitType: SplitType.itemized,
            participants: {'alice': 1},
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
            items: [
              LineItem(
                id: 'item1',
                name: 'Item',
                quantity: Decimal.parse('3.141592'),
                unitPrice: Decimal.parse('10.606060'),
                taxable: false,
                serviceChargeable: false,
                assignment: const ItemAssignment(
                  mode: AssignmentMode.even,
                  users: ['alice'],
                ),
              ),
            ],
            participantAmounts: {'alice': Decimal.parse('33.333333')},
          );

          // Act
          final json = ExpenseModel.toJson(expense);
          final mockDoc = _MockDocumentSnapshot('exp1', json);
          final deserialized = ExpenseModel.fromFirestore(mockDoc);

          // Assert - Verify precision preserved
          expect(deserialized.amount, Decimal.parse('33.333333'));
          expect(deserialized.items![0].quantity, Decimal.parse('3.141592'));
          expect(deserialized.items![0].unitPrice, Decimal.parse('10.606060'));
          expect(
            deserialized.participantAmounts!['alice'],
            Decimal.parse('33.333333'),
          );
        },
      );

      test('should handle VND currency (0 decimal places)', () {
        // Arrange
        final expense = Expense(
          id: 'exp1',
          tripId: 'trip1',
          date: testDate,
          payerUserId: 'alice',
          currency: CurrencyCode.vnd,
          amount: Decimal.parse('50000'),
          description: 'Vietnamese dong',
          categoryId: 'food',
          splitType: SplitType.itemized,
          participants: {'alice': 1, 'bob': 1},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          items: [
            LineItem(
              id: 'item1',
              name: 'Pho',
              quantity: Decimal.fromInt(2),
              unitPrice: Decimal.parse('25000'),
              taxable: false,
              serviceChargeable: false,
              assignment: const ItemAssignment(
                mode: AssignmentMode.even,
                users: ['alice', 'bob'],
              ),
            ),
          ],
        );

        // Act
        final json = ExpenseModel.toJson(expense);
        final mockDoc = _MockDocumentSnapshot('exp1', json);
        final deserialized = ExpenseModel.fromFirestore(mockDoc);

        // Assert
        expect(deserialized.currency, CurrencyCode.vnd);
        expect(deserialized.amount, Decimal.parse('50000'));
        expect(deserialized.items![0].unitPrice, Decimal.parse('25000'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty items list', () {
        // Arrange
        final expense = Expense(
          id: 'exp1',
          tripId: 'trip1',
          date: testDate,
          payerUserId: 'alice',
          currency: CurrencyCode.usd,
          amount: Decimal.zero,
          description: 'Empty items',
          categoryId: 'test',
          splitType: SplitType.itemized,
          participants: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          items: [], // Empty list
        );

        // Act
        final json = ExpenseModel.toJson(expense);
        final mockDoc = _MockDocumentSnapshot('exp1', json);
        final deserialized = ExpenseModel.fromFirestore(mockDoc);

        // Assert
        expect(deserialized.items, isNotNull);
        expect(deserialized.items, isEmpty);
      });

      test(
        'should handle complex nested structures with multiple fees and discounts',
        () {
          // Arrange - Multiple fees and discounts
          final expense = Expense(
            id: 'exp1',
            tripId: 'trip1',
            date: testDate,
            payerUserId: 'alice',
            currency: CurrencyCode.usd,
            amount: Decimal.parse('100.00'),
            description: 'Complex expense',
            categoryId: 'food',
            splitType: SplitType.itemized,
            participants: {'alice': 1, 'bob': 1},
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
            items: [
              LineItem(
                id: 'item1',
                name: 'Item 1',
                quantity: Decimal.fromInt(1),
                unitPrice: Decimal.parse('50.00'),
                taxable: true,
                serviceChargeable: true,
                assignment: const ItemAssignment(
                  mode: AssignmentMode.even,
                  users: ['alice', 'bob'],
                ),
              ),
            ],
            extras: Extras(
              tax: TaxExtra.percent(
                value: Decimal.parse('10'),
                base: PercentBase.preTaxItemSubtotals,
              ),
              tip: TipExtra.percent(
                value: Decimal.parse('15'),
                base: PercentBase.preTaxItemSubtotals,
              ),
              fees: [
                FeeExtra(
                  id: 'fee1',
                  name: 'Delivery',
                  type: 'amount',
                  value: Decimal.parse('5.00'),
                ),
                FeeExtra(
                  id: 'fee2',
                  name: 'Service',
                  type: 'percent',
                  value: Decimal.parse('3'),
                  base: PercentBase.preTaxItemSubtotals,
                ),
                FeeExtra(
                  id: 'fee3',
                  name: 'Packaging',
                  type: 'amount',
                  value: Decimal.parse('2.00'),
                ),
              ],
              discounts: [
                DiscountExtra(
                  id: 'disc1',
                  name: 'Promo',
                  type: 'amount',
                  value: Decimal.parse('10.00'),
                ),
                DiscountExtra(
                  id: 'disc2',
                  name: 'Member',
                  type: 'percent',
                  value: Decimal.parse('5'),
                  base: PercentBase.preTaxItemSubtotals,
                ),
              ],
            ),
          );

          // Act
          final json = ExpenseModel.toJson(expense);
          final mockDoc = _MockDocumentSnapshot('exp1', json);
          final deserialized = ExpenseModel.fromFirestore(mockDoc);

          // Assert
          expect(deserialized.extras!.fees.length, 3);
          expect(deserialized.extras!.discounts.length, 2);
          expect(deserialized.extras!.fees[0].name, 'Delivery');
          expect(deserialized.extras!.fees[1].name, 'Service');
          expect(deserialized.extras!.discounts[0].name, 'Promo');
        },
      );

      test('should handle participant breakdown with many participants', () {
        // Arrange - 5 participants
        final participantBreakdown = <String, ParticipantBreakdown>{};
        for (int i = 0; i < 5; i++) {
          final userId = 'user$i';
          participantBreakdown[userId] = ParticipantBreakdown(
            userId: userId,
            itemsSubtotal: Decimal.parse('10.00'),
            extrasAllocated: {'tax': Decimal.zero},
            roundedAdjustment: Decimal.zero,
            total: Decimal.parse('10.00'),
            items: [
              ItemContribution(
                itemId: 'item1',
                itemName: 'Shared Item',
                quantity: Decimal.fromInt(1),
                unitPrice: Decimal.parse('50.00'),
                assignedShare: Decimal.parse('0.2'),
              ),
            ],
          );
        }

        final expense = Expense(
          id: 'exp1',
          tripId: 'trip1',
          date: testDate,
          payerUserId: 'user0',
          currency: CurrencyCode.usd,
          amount: Decimal.parse('50.00'),
          description: 'Many participants',
          categoryId: 'food',
          splitType: SplitType.itemized,
          participants: {
            'user0': 1,
            'user1': 1,
            'user2': 1,
            'user3': 1,
            'user4': 1,
          },
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          participantBreakdown: participantBreakdown,
        );

        // Act
        final json = ExpenseModel.toJson(expense);
        final mockDoc = _MockDocumentSnapshot('exp1', json);
        final deserialized = ExpenseModel.fromFirestore(mockDoc);

        // Assert
        expect(deserialized.participantBreakdown, isNotNull);
        expect(deserialized.participantBreakdown!.length, 5);
        for (int i = 0; i < 5; i++) {
          final userId = 'user$i';
          expect(deserialized.participantBreakdown![userId], isNotNull);
          expect(deserialized.participantBreakdown![userId]!.userId, userId);
        }
      });
    });
  });
}

/// Mock DocumentSnapshot for testing
class _MockDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
