import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/data/models/line_item_model.dart';
import 'package:expense_tracker/features/expenses/data/models/extras_model.dart';
import 'package:expense_tracker/features/expenses/data/models/allocation_rule_model.dart';
import 'package:expense_tracker/features/expenses/data/models/participant_breakdown_model.dart';
import 'package:expense_tracker/features/expenses/domain/models/line_item.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_assignment.dart';
import 'package:expense_tracker/features/expenses/domain/models/assignment_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/extras.dart';
import 'package:expense_tracker/features/expenses/domain/models/tax_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/tip_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/fee_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/discount_extra.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';
import 'package:expense_tracker/features/expenses/domain/models/allocation_rule.dart';
import 'package:expense_tracker/features/expenses/domain/models/absolute_split_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_config.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/remainder_distribution_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/participant_breakdown.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_contribution.dart';

void main() {
  group('LineItemModel serialization', () {
    test('serializes and deserializes even assignment', () {
      final lineItem = LineItem(
        id: 'item1',
        name: 'Burger',
        quantity: Decimal.parse('2'),
        unitPrice: Decimal.parse('15.99'),
        taxable: true,
        serviceChargeable: true,
        assignment: const ItemAssignment(
          mode: AssignmentMode.even,
          users: ['user1', 'user2', 'user3'],
        ),
      );

      // Serialize
      final json = LineItemModel.toJson(lineItem);

      // Deserialize
      final restored = LineItemModel.fromJson(json);

      // Verify
      expect(restored, equals(lineItem));
      expect(restored.quantity, lineItem.quantity);
      expect(restored.unitPrice, lineItem.unitPrice);
      expect(restored.taxable, lineItem.taxable);
      expect(restored.serviceChargeable, lineItem.serviceChargeable);
      expect(restored.assignment.mode, AssignmentMode.even);
      expect(restored.assignment.users, ['user1', 'user2', 'user3']);
      expect(restored.assignment.shares, isNull);
    });

    test('serializes and deserializes custom assignment with shares', () {
      final lineItem = LineItem(
        id: 'item2',
        name: 'Pizza',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('25.00'),
        taxable: true,
        serviceChargeable: true,
        assignment: ItemAssignment(
          mode: AssignmentMode.custom,
          users: const ['user1', 'user2'],
          shares: {
            'user1': Decimal.parse('0.6'),
            'user2': Decimal.parse('0.4'),
          },
        ),
      );

      // Serialize
      final json = LineItemModel.toJson(lineItem);

      // Deserialize
      final restored = LineItemModel.fromJson(json);

      // Verify
      expect(restored, equals(lineItem));
      expect(restored.assignment.mode, AssignmentMode.custom);
      expect(restored.assignment.shares, isNotNull);
      expect(restored.assignment.shares!['user1'], Decimal.parse('0.6'));
      expect(restored.assignment.shares!['user2'], Decimal.parse('0.4'));
    });

    test('serializes and deserializes decimal quantity and unitPrice', () {
      final lineItem = LineItem(
        id: 'item3',
        name: 'Cheese by pound',
        quantity: Decimal.parse('0.5'),
        unitPrice: Decimal.parse('15.99'),
        taxable: true,
        serviceChargeable: false,
        assignment: const ItemAssignment(
          mode: AssignmentMode.even,
          users: ['user1'],
        ),
      );

      // Serialize
      final json = LineItemModel.toJson(lineItem);

      // Verify string storage
      expect(json['quantity'], '0.5');
      expect(json['unitPrice'], '15.99');

      // Deserialize
      final restored = LineItemModel.fromJson(json);

      // Verify exact decimal precision (no floating point errors)
      expect(restored.quantity, Decimal.parse('0.5'));
      expect(restored.unitPrice, Decimal.parse('15.99'));
      expect(restored.itemTotal, Decimal.parse('7.995'));
    });

    test('serializes and deserializes taxable and serviceChargeable flags', () {
      final lineItem1 = LineItem(
        id: 'item4',
        name: 'Taxable item',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('10.00'),
        taxable: true,
        serviceChargeable: false,
        assignment: const ItemAssignment(
          mode: AssignmentMode.even,
          users: ['user1'],
        ),
      );

      final json1 = LineItemModel.toJson(lineItem1);
      final restored1 = LineItemModel.fromJson(json1);

      expect(restored1.taxable, true);
      expect(restored1.serviceChargeable, false);

      final lineItem2 = LineItem(
        id: 'item5',
        name: 'Non-taxable item',
        quantity: Decimal.parse('1'),
        unitPrice: Decimal.parse('10.00'),
        taxable: false,
        serviceChargeable: true,
        assignment: const ItemAssignment(
          mode: AssignmentMode.even,
          users: ['user1'],
        ),
      );

      final json2 = LineItemModel.toJson(lineItem2);
      final restored2 = LineItemModel.fromJson(json2);

      expect(restored2.taxable, false);
      expect(restored2.serviceChargeable, true);
    });
  });

  group('ExtrasModel serialization', () {
    test('serializes and deserializes with all fields populated', () {
      final extras = Extras(
        tax: TaxExtra.percent(
          value: Decimal.parse('8.5'),
          base: PercentBase.preTaxItemSubtotals,
        ),
        tip: TipExtra.percent(
          value: Decimal.parse('18'),
          base: PercentBase.postTaxSubtotals,
        ),
        fees: [
          FeeExtra(
            id: 'fee1',
            name: 'Service Fee',
            type: 'percent',
            value: Decimal.parse('3'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          FeeExtra(
            id: 'fee2',
            name: 'Delivery Fee',
            type: 'amount',
            value: Decimal.parse('5.00'),
            base: null,
          ),
        ],
        discounts: [
          DiscountExtra(
            id: 'disc1',
            name: 'Happy Hour',
            type: 'percent',
            value: Decimal.parse('20'),
            base: PercentBase.preTaxItemSubtotals,
          ),
        ],
      );

      // Serialize
      final json = ExtrasModel.toJson(extras);

      // Deserialize
      final restored = ExtrasModel.fromJson(json);

      // Verify
      expect(restored, equals(extras));
      expect(restored.tax, isNotNull);
      expect(restored.tax!.value, Decimal.parse('8.5'));
      expect(restored.tax!.base, PercentBase.preTaxItemSubtotals);
      expect(restored.tip, isNotNull);
      expect(restored.tip!.value, Decimal.parse('18'));
      expect(restored.fees, hasLength(2));
      expect(restored.discounts, hasLength(1));
    });

    test(
      'serializes and deserializes with only tax (nullable tip, empty lists)',
      () {
        final extras = Extras(
          tax: TaxExtra.percent(
            value: Decimal.parse('8.5'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          tip: null,
          fees: const [],
          discounts: const [],
        );

        // Serialize
        final json = ExtrasModel.toJson(extras);

        // Verify JSON structure
        expect(json['tax'], isNotNull);
        expect(json['tip'], isNull);
        expect(json['fees'], isEmpty);
        expect(json['discounts'], isEmpty);

        // Deserialize
        final restored = ExtrasModel.fromJson(json);

        // Verify
        expect(restored.tax, isNotNull);
        expect(restored.tip, isNull);
        expect(restored.fees, isEmpty);
        expect(restored.discounts, isEmpty);
      },
    );

    test(
      'serializes and deserializes percent-based tax with preTaxItemSubtotals base',
      () {
        final extras = Extras(
          tax: TaxExtra.percent(
            value: Decimal.parse('8.5'),
            base: PercentBase.preTaxItemSubtotals,
          ),
          tip: null,
          fees: const [],
          discounts: const [],
        );

        // Serialize
        final json = ExtrasModel.toJson(extras);

        // Verify tax JSON structure
        expect(json['tax']['type'], 'percent');
        expect(json['tax']['value'], '8.5');
        expect(json['tax']['base'], 'preTaxItemSubtotals');

        // Deserialize
        final restored = ExtrasModel.fromJson(json);

        // Verify exact decimal precision
        expect(restored.tax!.type, 'percent');
        expect(restored.tax!.value, Decimal.parse('8.5'));
        expect(restored.tax!.base, PercentBase.preTaxItemSubtotals);
      },
    );

    test('serializes and deserializes amount-based tip', () {
      final extras = Extras(
        tax: null,
        tip: TipExtra.amount(value: Decimal.parse('5.00')),
        fees: const [],
        discounts: const [],
      );

      // Serialize
      final json = ExtrasModel.toJson(extras);

      // Verify tip JSON structure (Decimal.toString() may not preserve trailing zeros)
      expect(json['tip']['type'], 'amount');
      expect(
        Decimal.parse(json['tip']['value'] as String),
        Decimal.parse('5.00'),
      );
      expect(json['tip']['base'], isNull);

      // Deserialize
      final restored = ExtrasModel.fromJson(json);

      // Verify
      expect(restored.tip!.type, 'amount');
      expect(restored.tip!.value, Decimal.parse('5.00'));
      expect(restored.tip!.base, isNull);
    });

    test('serializes and deserializes fee with percent type', () {
      final extras = Extras(
        tax: null,
        tip: null,
        fees: [
          FeeExtra(
            id: 'fee1',
            name: 'Service Charge',
            type: 'percent',
            value: Decimal.parse('15'),
            base: PercentBase.preTaxItemSubtotals,
          ),
        ],
        discounts: const [],
      );

      // Serialize
      final json = ExtrasModel.toJson(extras);

      // Deserialize
      final restored = ExtrasModel.fromJson(json);

      // Verify
      expect(restored.fees, hasLength(1));
      expect(restored.fees[0].id, 'fee1');
      expect(restored.fees[0].name, 'Service Charge');
      expect(restored.fees[0].type, 'percent');
      expect(restored.fees[0].value, Decimal.parse('15'));
      expect(restored.fees[0].base, PercentBase.preTaxItemSubtotals);
    });

    test('serializes and deserializes discount with amount type', () {
      final extras = Extras(
        tax: null,
        tip: null,
        fees: const [],
        discounts: [
          DiscountExtra(
            id: 'disc1',
            name: 'Coupon',
            type: 'amount',
            value: Decimal.parse('10.00'),
            base: null,
          ),
        ],
      );

      // Serialize
      final json = ExtrasModel.toJson(extras);

      // Deserialize
      final restored = ExtrasModel.fromJson(json);

      // Verify
      expect(restored.discounts, hasLength(1));
      expect(restored.discounts[0].id, 'disc1');
      expect(restored.discounts[0].name, 'Coupon');
      expect(restored.discounts[0].type, 'amount');
      expect(restored.discounts[0].value, Decimal.parse('10.00'));
      expect(restored.discounts[0].base, isNull);
    });
  });

  group('AllocationRuleModel serialization', () {
    test('serializes and deserializes with all enums', () {
      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      // Serialize
      final json = AllocationRuleModel.toJson(rule);

      // Verify JSON structure
      expect(json['percentBase'], 'preTaxItemSubtotals');
      expect(json['absoluteSplit'], 'proportionalToItemsSubtotal');
      expect(json['rounding'], isNotNull);

      // Deserialize
      final restored = AllocationRuleModel.fromJson(json);

      // Verify
      expect(restored, equals(rule));
      expect(restored.percentBase, PercentBase.preTaxItemSubtotals);
      expect(
        restored.absoluteSplit,
        AbsoluteSplitMode.proportionalToItemsSubtotal,
      );
      expect(restored.rounding.precision, Decimal.parse('0.01'));
      expect(restored.rounding.mode, RoundingMode.roundHalfUp);
      expect(
        restored.rounding.distributeRemainderTo,
        RemainderDistributionMode.largestShare,
      );
    });

    test('roundtrip serialization preserves all fields', () {
      final rule = AllocationRule(
        percentBase: PercentBase.postTaxSubtotals,
        absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
        rounding: RoundingConfig(
          precision: Decimal.parse('1'),
          mode: RoundingMode.floor,
          distributeRemainderTo: RemainderDistributionMode.payer,
        ),
      );

      // Serialize
      final json = AllocationRuleModel.toJson(rule);

      // Deserialize
      final restored = AllocationRuleModel.fromJson(json);

      // Verify complete equality
      expect(restored, equals(rule));
      expect(restored.percentBase, rule.percentBase);
      expect(restored.absoluteSplit, rule.absoluteSplit);
      expect(restored.rounding.precision, rule.rounding.precision);
      expect(restored.rounding.mode, rule.rounding.mode);
      expect(
        restored.rounding.distributeRemainderTo,
        rule.rounding.distributeRemainderTo,
      );
    });

    test('serializes and deserializes RoundingConfig nested object', () {
      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      // Serialize
      final json = AllocationRuleModel.toJson(rule);

      // Verify RoundingConfig JSON structure
      expect(json['rounding']['precision'], '0.01');
      expect(json['rounding']['mode'], 'roundHalfUp');
      expect(json['rounding']['distributeRemainderTo'], 'largestShare');

      // Deserialize
      final restored = AllocationRuleModel.fromJson(json);

      // Verify RoundingConfig is correctly restored
      expect(restored.rounding.precision, Decimal.parse('0.01'));
      expect(restored.rounding.mode, RoundingMode.roundHalfUp);
      expect(
        restored.rounding.distributeRemainderTo,
        RemainderDistributionMode.largestShare,
      );
    });

    test('serializes and deserializes USD precision (0.01)', () {
      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      final json = AllocationRuleModel.toJson(rule);
      final restored = AllocationRuleModel.fromJson(json);

      expect(restored.rounding.precision, Decimal.parse('0.01'));
    });

    test('serializes and deserializes VND precision (1)', () {
      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: RoundingConfig(
          precision: Decimal.parse('1'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        ),
      );

      final json = AllocationRuleModel.toJson(rule);
      final restored = AllocationRuleModel.fromJson(json);

      expect(restored.rounding.precision, Decimal.parse('1'));
    });
  });

  group('ParticipantBreakdownModel serialization', () {
    test(
      'serializes and deserializes complete breakdown with item contributions',
      () {
        final breakdown = ParticipantBreakdown(
          userId: 'user1',
          itemsSubtotal: Decimal.parse('42.50'),
          extrasAllocated: {
            'tax': Decimal.parse('3.61'),
            'tip': Decimal.parse('8.30'),
            'fee1': Decimal.parse('2.13'),
          },
          roundedAdjustment: Decimal.parse('0.02'),
          total: Decimal.parse('56.56'),
          items: [
            ItemContribution(
              itemId: 'item1',
              itemName: 'Burger',
              quantity: Decimal.parse('1'),
              unitPrice: Decimal.parse('15.99'),
              assignedShare: Decimal.parse('15.99'),
            ),
            ItemContribution(
              itemId: 'item2',
              itemName: 'Pizza',
              quantity: Decimal.parse('2'),
              unitPrice: Decimal.parse('12.50'),
              assignedShare: Decimal.parse('16.67'),
            ),
            ItemContribution(
              itemId: 'item3',
              itemName: 'Salad',
              quantity: Decimal.parse('0.5'),
              unitPrice: Decimal.parse('8.00'),
              assignedShare: Decimal.parse('9.84'),
            ),
          ],
        );

        // Serialize
        final json = ParticipantBreakdownModel.toJson(breakdown);

        // Deserialize
        final restored = ParticipantBreakdownModel.fromJson(json);

        // Verify
        expect(restored, equals(breakdown));
        expect(restored.userId, 'user1');
        expect(restored.itemsSubtotal, Decimal.parse('42.50'));
        expect(restored.total, Decimal.parse('56.56'));
        expect(restored.items, hasLength(3));
      },
    );

    test(
      'serializes and deserializes extrasAllocated map (Decimal to string to Decimal)',
      () {
        final breakdown = ParticipantBreakdown(
          userId: 'user2',
          itemsSubtotal: Decimal.parse('25.00'),
          extrasAllocated: {
            'tax': Decimal.parse('2.125'),
            'tip': Decimal.parse('4.50'),
          },
          roundedAdjustment: Decimal.parse('0.00'),
          total: Decimal.parse('31.625'),
          items: const [],
        );

        // Serialize
        final json = ParticipantBreakdownModel.toJson(breakdown);

        // Verify string storage (note: Decimal.toString() may not preserve trailing zeros)
        expect(json['extrasAllocated']['tax'], '2.125');
        expect(
          Decimal.parse(json['extrasAllocated']['tip'] as String),
          Decimal.parse('4.50'),
        );

        // Deserialize
        final restored = ParticipantBreakdownModel.fromJson(json);

        // Verify exact decimal precision
        expect(restored.extrasAllocated['tax'], Decimal.parse('2.125'));
        expect(restored.extrasAllocated['tip'], Decimal.parse('4.50'));
      },
    );

    test(
      'serializes and deserializes roundedAdjustment and total preservation',
      () {
        final breakdown = ParticipantBreakdown(
          userId: 'user3',
          itemsSubtotal: Decimal.parse('100.00'),
          extrasAllocated: {'tax': Decimal.parse('8.50')},
          roundedAdjustment: Decimal.parse('-0.01'),
          total: Decimal.parse('108.49'),
          items: const [],
        );

        // Serialize
        final json = ParticipantBreakdownModel.toJson(breakdown);

        // Verify string storage (Decimal.toString() may not preserve trailing zeros)
        expect(
          Decimal.parse(json['itemsSubtotal'] as String),
          Decimal.parse('100.00'),
        );
        expect(json['roundedAdjustment'], '-0.01');
        expect(json['total'], '108.49');

        // Deserialize
        final restored = ParticipantBreakdownModel.fromJson(json);

        // Verify exact precision
        expect(restored.itemsSubtotal, Decimal.parse('100.00'));
        expect(restored.roundedAdjustment, Decimal.parse('-0.01'));
        expect(restored.total, Decimal.parse('108.49'));
      },
    );

    test('serializes and deserializes nested ItemContribution', () {
      final breakdown = ParticipantBreakdown(
        userId: 'user4',
        itemsSubtotal: Decimal.parse('31.98'),
        extrasAllocated: const {},
        roundedAdjustment: Decimal.parse('0.00'),
        total: Decimal.parse('31.98'),
        items: [
          ItemContribution(
            itemId: 'item1',
            itemName: 'Pizza',
            quantity: Decimal.parse('2.5'),
            unitPrice: Decimal.parse('15.99'),
            assignedShare: Decimal.parse('31.98'),
          ),
        ],
      );

      // Serialize
      final json = ParticipantBreakdownModel.toJson(breakdown);

      // Verify ItemContribution JSON structure
      expect(json['items'], hasLength(1));
      expect(json['items'][0]['itemId'], 'item1');
      expect(json['items'][0]['itemName'], 'Pizza');
      expect(json['items'][0]['quantity'], '2.5');
      expect(json['items'][0]['unitPrice'], '15.99');
      expect(json['items'][0]['assignedShare'], '31.98');

      // Deserialize
      final restored = ParticipantBreakdownModel.fromJson(json);

      // Verify ItemContribution is correctly restored
      expect(restored.items[0].itemId, 'item1');
      expect(restored.items[0].itemName, 'Pizza');
      expect(restored.items[0].quantity, Decimal.parse('2.5'));
      expect(restored.items[0].unitPrice, Decimal.parse('15.99'));
      expect(restored.items[0].assignedShare, Decimal.parse('31.98'));
    });
  });

  group('Golden JSON fixture tests', () {
    test('LineItemModel fromJson with realistic JSON structure', () {
      final json = {
        'id': 'item_001',
        'name': 'Grilled Salmon',
        'quantity': '2',
        'unitPrice': '15.99',
        'taxable': true,
        'serviceChargeable': true,
        'assignment': {
          'mode': 'even',
          'users': ['user1', 'user2'],
        },
      };

      final lineItem = LineItemModel.fromJson(json);

      expect(lineItem.id, 'item_001');
      expect(lineItem.name, 'Grilled Salmon');
      expect(lineItem.quantity, Decimal.parse('2'));
      expect(lineItem.unitPrice, Decimal.parse('15.99'));
      expect(lineItem.itemTotal, Decimal.parse('31.98'));
      expect(lineItem.taxable, true);
      expect(lineItem.serviceChargeable, true);
    });

    test(
      'ExtrasModel fromJson with realistic Firestore document structure',
      () {
        final json = {
          'tax': {
            'type': 'percent',
            'value': '8.5',
            'base': 'preTaxItemSubtotals',
          },
          'tip': {'type': 'percent', 'value': '18', 'base': 'postTaxSubtotals'},
          'fees': [
            {
              'id': 'fee_service',
              'name': 'Service Charge',
              'type': 'percent',
              'value': '3',
              'base': 'preTaxItemSubtotals',
            },
          ],
          'discounts': [],
        };

        final extras = ExtrasModel.fromJson(json);

        expect(extras.tax, isNotNull);
        expect(extras.tax!.value, Decimal.parse('8.5'));
        expect(extras.tip, isNotNull);
        expect(extras.tip!.value, Decimal.parse('18'));
        expect(extras.fees, hasLength(1));
        expect(extras.discounts, isEmpty);
      },
    );

    test(
      'AllocationRuleModel fromJson with realistic Firestore document structure',
      () {
        final json = {
          'percentBase': 'preTaxItemSubtotals',
          'absoluteSplit': 'proportionalToItemsSubtotal',
          'rounding': {
            'precision': '0.01',
            'mode': 'roundHalfUp',
            'distributeRemainderTo': 'largestShare',
          },
        };

        final rule = AllocationRuleModel.fromJson(json);

        expect(rule.percentBase, PercentBase.preTaxItemSubtotals);
        expect(
          rule.absoluteSplit,
          AbsoluteSplitMode.proportionalToItemsSubtotal,
        );
        expect(rule.rounding.precision, Decimal.parse('0.01'));
      },
    );

    test(
      'ParticipantBreakdownModel fromJson with realistic Firestore document structure',
      () {
        final json = {
          'userId': 'user_tai',
          'itemsSubtotal': '42.50',
          'extrasAllocated': {'tax': '3.61', 'tip': '8.30'},
          'roundedAdjustment': '0.02',
          'total': '54.43',
          'items': [
            {
              'itemId': 'item_001',
              'itemName': 'Burger',
              'quantity': '1',
              'unitPrice': '15.99',
              'assignedShare': '15.99',
            },
            {
              'itemId': 'item_002',
              'itemName': 'Pizza',
              'quantity': '2',
              'unitPrice': '12.50',
              'assignedShare': '26.51',
            },
          ],
        };

        final breakdown = ParticipantBreakdownModel.fromJson(json);

        expect(breakdown.userId, 'user_tai');
        expect(breakdown.itemsSubtotal, Decimal.parse('42.50'));
        expect(breakdown.total, Decimal.parse('54.43'));
        expect(breakdown.items, hasLength(2));
        expect(breakdown.extrasAllocated['tax'], Decimal.parse('3.61'));
      },
    );

    test('Decimal precision is maintained (no floating point errors)', () {
      final lineItemJson = {
        'id': 'item1',
        'name': 'Test',
        'quantity': '2.5',
        'unitPrice': '15.99',
        'taxable': true,
        'serviceChargeable': true,
        'assignment': {
          'mode': 'even',
          'users': ['user1'],
        },
      };

      final lineItem = LineItemModel.fromJson(lineItemJson);

      // Verify no floating point errors
      expect(lineItem.quantity.toString(), '2.5');
      expect(lineItem.unitPrice.toString(), '15.99');
      expect(lineItem.itemTotal.toString(), '39.975');

      final breakdownJson = {
        'userId': 'user1',
        'itemsSubtotal': '100.00',
        'extrasAllocated': {'tax': '8.50'},
        'roundedAdjustment': '0.00',
        'total': '108.50',
        'items': [],
      };

      final breakdown = ParticipantBreakdownModel.fromJson(breakdownJson);

      // Verify exact decimal values
      expect(breakdown.itemsSubtotal, Decimal.parse('100.00'));
      expect(breakdown.extrasAllocated['tax'], Decimal.parse('8.50'));
      expect(breakdown.total, Decimal.parse('108.50'));
    });
  });
}
