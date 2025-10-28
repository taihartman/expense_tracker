import 'package:decimal/decimal.dart';
import '../../domain/models/absolute_split_mode.dart';
import '../../domain/models/allocation_rule.dart';
import '../../domain/models/percent_base.dart';
import '../../domain/models/remainder_distribution_mode.dart';
import '../../domain/models/rounding_config.dart';
import '../../domain/models/rounding_mode.dart';

/// Firestore model for AllocationRule entity
///
/// Handles serialization/deserialization between domain entity and Firestore documents
class AllocationRuleModel {
  /// Convert AllocationRule domain entity to Firestore JSON
  static Map<String, dynamic> toJson(AllocationRule rule) {
    return {
      'percentBase': rule.percentBase.name,
      'absoluteSplit': rule.absoluteSplit.name,
      'rounding': _roundingConfigToJson(rule.rounding),
    };
  }

  /// Convert Firestore JSON to AllocationRule domain entity
  static AllocationRule fromJson(Map<String, dynamic> data) {
    return AllocationRule(
      percentBase:
          PercentBase.fromString(data['percentBase'] as String) ??
          PercentBase.preTaxItemSubtotals,
      absoluteSplit:
          AbsoluteSplitMode.fromString(data['absoluteSplit'] as String) ??
          AbsoluteSplitMode.proportionalToItemsSubtotal,
      rounding: _roundingConfigFromJson(
        data['rounding'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convert RoundingConfig to JSON (inline serialization)
  static Map<String, dynamic> _roundingConfigToJson(RoundingConfig config) {
    return {
      'precision': config.precision.toString(),
      'mode': config.mode.name,
      'distributeRemainderTo': config.distributeRemainderTo.name,
    };
  }

  /// Convert JSON to RoundingConfig (inline deserialization)
  static RoundingConfig _roundingConfigFromJson(Map<String, dynamic> data) {
    return RoundingConfig(
      precision: Decimal.parse(data['precision'] as String),
      mode:
          RoundingMode.fromString(data['mode'] as String) ??
          RoundingMode.roundHalfUp,
      distributeRemainderTo:
          RemainderDistributionMode.fromString(
            data['distributeRemainderTo'] as String,
          ) ??
          RemainderDistributionMode.largestShare,
    );
  }
}
