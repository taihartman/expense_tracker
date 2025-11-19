import 'package:equatable/equatable.dart';
import '../../domain/models/settlement_summary.dart';
import '../../domain/models/minimal_transfer.dart';
import '../../domain/models/category_spending.dart';

/// Filter mode for transfer filtering
enum TransferFilterMode {
  all, // Show all transfers involving the user
  owes, // Show only transfers where user owes money
  owed, // Show only transfers where user is owed money
}

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
  final List<MinimalTransfer> activeTransfers;
  final List<MinimalTransfer> settledTransfers;
  final Map<String, PersonCategorySpending>? personCategorySpending;
  final String? selectedUserId; // User ID for filtering transfers
  final TransferFilterMode filterMode; // Filter mode (all/owes/owed)
  final List<String>? validationWarnings; // Warnings from settlement validation

  const SettlementLoaded({
    required this.summary,
    required this.activeTransfers,
    required this.settledTransfers,
    this.personCategorySpending,
    this.selectedUserId,
    this.filterMode = TransferFilterMode.all,
    this.validationWarnings,
  });

  @override
  List<Object?> get props => [
    summary,
    activeTransfers,
    settledTransfers,
    personCategorySpending,
    selectedUserId,
    filterMode,
    validationWarnings,
  ];

  /// Get all transfers (active + settled)
  List<MinimalTransfer> get allTransfers => [
    ...activeTransfers,
    ...settledTransfers,
  ];

  SettlementLoaded copyWith({
    SettlementSummary? summary,
    List<MinimalTransfer>? activeTransfers,
    List<MinimalTransfer>? settledTransfers,
    Map<String, PersonCategorySpending>? personCategorySpending,
    String? selectedUserId,
    TransferFilterMode? filterMode,
    List<String>? validationWarnings,
    bool clearFilter = false, // Flag to clear selectedUserId
  }) {
    return SettlementLoaded(
      summary: summary ?? this.summary,
      activeTransfers: activeTransfers ?? this.activeTransfers,
      settledTransfers: settledTransfers ?? this.settledTransfers,
      personCategorySpending:
          personCategorySpending ?? this.personCategorySpending,
      selectedUserId: clearFilter
          ? null
          : (selectedUserId ?? this.selectedUserId),
      filterMode: filterMode ?? this.filterMode,
      validationWarnings: validationWarnings ?? this.validationWarnings,
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
