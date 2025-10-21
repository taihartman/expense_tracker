import 'package:equatable/equatable.dart';
import '../../domain/models/settlement_summary.dart';
import '../../domain/models/minimal_transfer.dart';

/// Base state for SettlementCubit
abstract class SettlementState extends Equatable {
  const SettlementState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any settlement is loaded
class SettlementInitial extends SettlementState {
  const SettlementInitial();
}

/// Loading settlement data
class SettlementLoading extends SettlementState {
  const SettlementLoading();
}

/// Computing settlement (can take time for many expenses)
class SettlementComputing extends SettlementState {
  const SettlementComputing();
}

/// Settlement data loaded successfully
class SettlementLoaded extends SettlementState {
  final SettlementSummary summary;
  final List<MinimalTransfer> transfers;

  const SettlementLoaded({
    required this.summary,
    required this.transfers,
  });

  @override
  List<Object?> get props => [summary, transfers];

  SettlementLoaded copyWith({
    SettlementSummary? summary,
    List<MinimalTransfer>? transfers,
  }) {
    return SettlementLoaded(
      summary: summary ?? this.summary,
      transfers: transfers ?? this.transfers,
    );
  }
}

/// Error loading or computing settlement
class SettlementError extends SettlementState {
  final String message;

  const SettlementError(this.message);

  @override
  List<Object?> get props => [message];
}
