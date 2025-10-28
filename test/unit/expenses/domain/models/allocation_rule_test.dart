import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expenses/domain/models/allocation_rule.dart';
import 'package:expense_tracker/features/expenses/domain/models/percent_base.dart';
import 'package:expense_tracker/features/expenses/domain/models/absolute_split_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_config.dart';
import 'package:expense_tracker/features/expenses/domain/models/rounding_mode.dart';
import 'package:expense_tracker/features/expenses/domain/models/remainder_distribution_mode.dart';
import 'package:decimal/decimal.dart';

void main() {
  group('AllocationRule', () {
    final defaultRounding = RoundingConfig(
      precision: Decimal.parse('0.01'),
      mode: RoundingMode.roundHalfUp,
      distributeRemainderTo: RemainderDistributionMode.largestShare,
    );

    group('creation with various combinations', () {
      test('creates allocation rule with all properties', () {
        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: defaultRounding,
        );

        expect(rule.percentBase, PercentBase.preTaxItemSubtotals);
        expect(rule.absoluteSplit, AbsoluteSplitMode.proportionalToItemsSubtotal);
        expect(rule.rounding, defaultRounding);
      });

      test('creates allocation rule with post-tax percent base', () {
        final rule = AllocationRule(
          percentBase: PercentBase.postTaxSubtotals,
          absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
          rounding: defaultRounding,
        );

        expect(rule.percentBase, PercentBase.postTaxSubtotals);
        expect(rule.absoluteSplit, AbsoluteSplitMode.evenAcrossAssignedPeople);
      });

      test('creates allocation rule with post-discount percent base', () {
        final rule = AllocationRule(
          percentBase: PercentBase.postDiscountItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: defaultRounding,
        );

        expect(rule.percentBase, PercentBase.postDiscountItemSubtotals);
      });

      test('creates allocation rule with taxable items only percent base', () {
        final rule = AllocationRule(
          percentBase: PercentBase.taxableItemSubtotalsOnly,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: defaultRounding,
        );

        expect(rule.percentBase, PercentBase.taxableItemSubtotalsOnly);
      });

      test('creates allocation rule with post-fees percent base', () {
        final rule = AllocationRule(
          percentBase: PercentBase.postFeesSubtotals,
          absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
          rounding: defaultRounding,
        );

        expect(rule.percentBase, PercentBase.postFeesSubtotals);
      });
    });

    group('different rounding configurations', () {
      test('creates allocation rule with VND rounding (precision = 1)', () {
        final vndRounding = RoundingConfig(
          precision: Decimal.parse('1'),
          mode: RoundingMode.roundHalfUp,
          distributeRemainderTo: RemainderDistributionMode.payer,
        );

        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: vndRounding,
        );

        expect(rule.rounding.precision, Decimal.parse('1'));
        expect(rule.rounding.mode, RoundingMode.roundHalfUp);
        expect(rule.rounding.distributeRemainderTo, RemainderDistributionMode.payer);
      });

      test('creates allocation rule with round half even mode', () {
        final customRounding = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundHalfEven,
          distributeRemainderTo: RemainderDistributionMode.largestShare,
        );

        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: customRounding,
        );

        expect(rule.rounding.mode, RoundingMode.roundHalfEven);
      });

      test('creates allocation rule with round down mode', () {
        final customRounding = RoundingConfig(
          precision: Decimal.parse('0.01'),
          mode: RoundingMode.roundDown,
          distributeRemainderTo: RemainderDistributionMode.smallestShare,
        );

        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: customRounding,
        );

        expect(rule.rounding.mode, RoundingMode.roundDown);
        expect(rule.rounding.distributeRemainderTo, RemainderDistributionMode.smallestShare);
      });
    });

    group('different split mode combinations', () {
      test('creates allocation rule with even split mode', () {
        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
          rounding: defaultRounding,
        );

        expect(rule.absoluteSplit, AbsoluteSplitMode.evenAcrossAssignedPeople);
      });

      test('creates allocation rule with proportional split mode', () {
        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: defaultRounding,
        );

        expect(rule.absoluteSplit, AbsoluteSplitMode.proportionalToItemsSubtotal);
      });
    });

    group('real-world scenarios', () {
      test('creates typical US restaurant allocation rule', () {
        // Tax on pre-tax items, tip on post-tax, split proportionally
        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        expect(rule.percentBase, PercentBase.preTaxItemSubtotals);
        expect(rule.absoluteSplit, AbsoluteSplitMode.proportionalToItemsSubtotal);
        expect(rule.rounding.precision, Decimal.parse('0.01'));
      });

      test('creates VND restaurant allocation rule', () {
        // VND has no decimals, round to whole numbers
        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: Decimal.parse('1'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.payer,
          ),
        );

        expect(rule.rounding.precision, Decimal.parse('1'));
      });

      test('creates even split allocation rule for simple bills', () {
        // Split all fees/discounts evenly, regardless of item amounts
        final rule = AllocationRule(
          percentBase: PercentBase.preTaxItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        expect(rule.absoluteSplit, AbsoluteSplitMode.evenAcrossAssignedPeople);
      });

      test('creates post-discount tax allocation rule', () {
        // Tax applied after discounts (happy hour scenario)
        final rule = AllocationRule(
          percentBase: PercentBase.postDiscountItemSubtotals,
          absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
          rounding: RoundingConfig(
            precision: Decimal.parse('0.01'),
            mode: RoundingMode.roundHalfUp,
            distributeRemainderTo: RemainderDistributionMode.largestShare,
          ),
        );

        expect(rule.percentBase, PercentBase.postDiscountItemSubtotals);
      });
    });

    test('supports equality comparison', () {
      final rule1 = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      final rule2 = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      expect(rule1, equals(rule2));
    });

    test('distinguishes different allocation rules', () {
      final rule1 = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      final rule2 = AllocationRule(
        percentBase: PercentBase.postTaxSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      expect(rule1, isNot(equals(rule2)));
    });

    test('distinguishes rules with different split modes', () {
      final rule1 = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      final rule2 = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
        rounding: defaultRounding,
      );

      expect(rule1, isNot(equals(rule2)));
    });

    test('distinguishes rules with different rounding configs', () {
      final rounding1 = RoundingConfig(
        precision: Decimal.parse('0.01'),
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.largestShare,
      );

      final rounding2 = RoundingConfig(
        precision: Decimal.parse('1'),
        mode: RoundingMode.roundHalfUp,
        distributeRemainderTo: RemainderDistributionMode.payer,
      );

      final rule1 = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: rounding1,
      );

      final rule2 = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: rounding2,
      );

      expect(rule1, isNot(equals(rule2)));
    });

    test('supports copyWith for percentBase', () {
      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      final updated = rule.copyWith(
        percentBase: PercentBase.postTaxSubtotals,
      );

      expect(updated.percentBase, PercentBase.postTaxSubtotals);
      expect(updated.absoluteSplit, AbsoluteSplitMode.proportionalToItemsSubtotal);
      expect(updated.rounding, defaultRounding);
    });

    test('supports copyWith for absoluteSplit', () {
      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      final updated = rule.copyWith(
        absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
      );

      expect(updated.percentBase, PercentBase.preTaxItemSubtotals);
      expect(updated.absoluteSplit, AbsoluteSplitMode.evenAcrossAssignedPeople);
      expect(updated.rounding, defaultRounding);
    });

    test('supports copyWith for rounding', () {
      final newRounding = RoundingConfig(
        precision: Decimal.parse('1'),
        mode: RoundingMode.roundHalfEven,
        distributeRemainderTo: RemainderDistributionMode.payer,
      );

      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      final updated = rule.copyWith(
        rounding: newRounding,
      );

      expect(updated.percentBase, PercentBase.preTaxItemSubtotals);
      expect(updated.absoluteSplit, AbsoluteSplitMode.proportionalToItemsSubtotal);
      expect(updated.rounding, newRounding);
    });

    test('supports copyWith with multiple fields', () {
      final newRounding = RoundingConfig(
        precision: Decimal.parse('1'),
        mode: RoundingMode.roundHalfEven,
        distributeRemainderTo: RemainderDistributionMode.payer,
      );

      final rule = AllocationRule(
        percentBase: PercentBase.preTaxItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.proportionalToItemsSubtotal,
        rounding: defaultRounding,
      );

      final updated = rule.copyWith(
        percentBase: PercentBase.postDiscountItemSubtotals,
        absoluteSplit: AbsoluteSplitMode.evenAcrossAssignedPeople,
        rounding: newRounding,
      );

      expect(updated.percentBase, PercentBase.postDiscountItemSubtotals);
      expect(updated.absoluteSplit, AbsoluteSplitMode.evenAcrossAssignedPeople);
      expect(updated.rounding, newRounding);
    });
  });
}
