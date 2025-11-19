import 'package:equatable/equatable.dart';
import 'settlement_summary.dart';

/// Result of a settlement computation including any validation warnings
class SettlementComputationResult extends Equatable {
  final SettlementSummary summary;
  final List<String>? validationWarnings;

  const SettlementComputationResult({
    required this.summary,
    this.validationWarnings,
  });

  /// Whether the computation has validation warnings
  bool get hasWarnings => validationWarnings != null && validationWarnings!.isNotEmpty;

  @override
  List<Object?> get props => [summary, validationWarnings];
}
