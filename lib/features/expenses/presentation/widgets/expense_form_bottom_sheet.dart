import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../cubits/expense_cubit.dart';
import '../cubits/itemized_expense_cubit.dart';
import '../pages/expense_form_page.dart';
import '../pages/itemized/itemized_expense_wizard.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../shared/utils/currency_input_formatter.dart';
import '../../../trips/presentation/cubits/trip_cubit.dart';
import '../../../trips/presentation/cubits/trip_state.dart';

/// Shows expense form in a Material 3 bottom sheet modal
void showExpenseFormBottomSheet({
  required BuildContext context,
  required String tripId,
  Expense? expense,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        ExpenseFormBottomSheet(tripId: tripId, expense: expense),
  );
}

/// Bottom sheet widget for expense form
class ExpenseFormBottomSheet extends StatefulWidget {
  final String tripId;
  final Expense? expense;

  const ExpenseFormBottomSheet({required this.tripId, this.expense, super.key});

  @override
  State<ExpenseFormBottomSheet> createState() => _ExpenseFormBottomSheetState();
}

class _ExpenseFormBottomSheetState extends State<ExpenseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  CurrencyCode _selectedCurrency = CurrencyCode.usd;
  String? _selectedPayer;
  SplitType _selectedSplitType = SplitType.equal;
  DateTime _selectedDate = DateTime.now();
  Map<String, num> _participants = {};
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializeFormState();
  }

  void _initializeFormState() {
    // Get available participants from trip
    final tripState = context.read<TripCubit>().state;
    List<Participant> availableParticipants = [];
    CurrencyCode? tripBaseCurrency;

    if (tripState is TripLoaded) {
      final trip = tripState.trips.firstWhere(
        (t) => t.id == widget.tripId,
        orElse: () => tripState.trips.first,
      );

      // Use trip participants and base currency
      availableParticipants = trip.participants;
      tripBaseCurrency = trip.baseCurrency;
    }

    if (widget.expense != null) {
      debugPrint(
        '🟣 [BottomSheet] Editing existing expense: ${widget.expense!.id}',
      );
      debugPrint('🟣 [BottomSheet] Split type: ${widget.expense!.splitType}');

      // Check if it's an itemized expense - open wizard instead of form
      if (widget.expense!.splitType == SplitType.itemized) {
        debugPrint(
          '🟣 [BottomSheet] Detected itemized expense - opening wizard for edit',
        );
        // Schedule wizard opening after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openItemizedWizardForEdit(widget.expense!, availableParticipants);
        });
        return;
      }

      // Editing existing expense (equal/weighted) - format the amount with commas
      final formatter = NumberFormat('#,##0.##', 'en_US');
      _amountController.text = formatter.format(
        widget.expense!.amount.toDouble(),
      );
      _descriptionController.text = widget.expense!.description ?? '';
      _selectedCurrency = widget.expense!.currency;
      _selectedPayer = widget.expense!.payerUserId;
      _selectedSplitType = widget.expense!.splitType;
      _selectedDate = widget.expense!.date;
      _participants = Map.from(widget.expense!.participants);
      _selectedCategory = widget.expense!.categoryId;
    } else {
      // New expense - set currency to trip's base currency
      if (tripBaseCurrency != null) {
        _selectedCurrency = tripBaseCurrency;
      }
      // Leave payer and participants unselected (removed auto-selection)
    }
  }

  Future<void> _openItemizedWizardForEdit(
    Expense expense,
    List<Participant> availableParticipants,
  ) async {
    debugPrint('🔵 [BottomSheet] Opening itemized wizard for edit mode');
    debugPrint('🔵 [BottomSheet] Expense ID: ${expense.id}');

    // Capture navigator, cubit, and l10n before async operation
    final navigator = Navigator.of(context);
    final expenseCubit = context.read<ExpenseCubit>();
    final l10n = context.l10n;

    try {
      final expenseRepository = context.read<ExpenseRepository>();
      debugPrint('🔵 [BottomSheet] ExpenseRepository obtained');

      // Navigate to itemized expense wizard with existing expense
      final result = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (context) {
            return BlocProvider(
              create: (context) =>
                  ItemizedExpenseCubit(expenseRepository: expenseRepository),
              child: ItemizedExpenseWizard(
                tripId: widget.tripId,
                participants: availableParticipants.map((p) => p.id).toList(),
                participantNames: {
                  for (var p in availableParticipants) p.id: p.name,
                },
                initialPayerUserId: expense.payerUserId,
                currency: expense.currency,
                existingExpense: expense, // Pass existing expense for edit mode
              ),
            );
          },
        ),
      );

      debugPrint('🔵 [BottomSheet] Wizard returned with result: $result');

      // Close bottom sheet and reload expenses if updated
      if (mounted) {
        if (result == true) {
          debugPrint('🔵 [BottomSheet] Expense updated - reloading list');
          // Force reload to get latest data from Firestore
          await expenseCubit.loadExpenses(widget.tripId);
          // Small delay to ensure stream emits
          await Future.delayed(const Duration(milliseconds: 150));
          debugPrint('🔵 [BottomSheet] Reload complete - closing bottom sheet');
        } else {
          debugPrint('🔵 [BottomSheet] No changes - closing bottom sheet');
        }
        navigator.pop();
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [BottomSheet] ERROR in itemized edit navigation: $e');
      debugPrint('🔴 [BottomSheet] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.expenseItemizedOpenError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        // Close bottom sheet on error
        navigator.pop();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm(List<Participant> tripParticipants) {
    if (_formKey.currentState!.validate()) {
      if (_selectedPayer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.validationPleaseSelectPayer)),
        );
        return;
      }

      if (_participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.validationPleaseSelectParticipants),
          ),
        );
        return;
      }

      final expense = Expense(
        id: widget.expense?.id ?? '',
        tripId: widget.tripId,
        date: _selectedDate,
        payerUserId: _selectedPayer!,
        currency: _selectedCurrency,
        amount: Decimal.parse(stripCurrencyFormatting(_amountController.text)),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        categoryId: _selectedCategory,
        splitType: _selectedSplitType,
        participants: _participants,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Get payer name for activity logging
      final payerName = tripParticipants
          .firstWhere(
            (p) => p.id == _selectedPayer,
            orElse: () => const Participant(id: '', name: ''),
          )
          .name;

      if (widget.expense != null) {
        // Update existing expense
        context.read<ExpenseCubit>().updateExpense(
          expense,
          payerName: payerName.isNotEmpty ? payerName : null,
        );
      } else {
        // Create new expense
        context.read<ExpenseCubit>().createExpense(
          expense,
          payerName: payerName.isNotEmpty ? payerName : null,
        );
      }

      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteExpense(List<Participant> tripParticipants) async {
    if (widget.expense == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.expenseDeleteDialogTitle),
        content: Text(context.l10n.expenseDeleteDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Get payer name for activity logging
      final payerName = tripParticipants
          .firstWhere(
            (p) => p.id == widget.expense!.payerUserId,
            orElse: () => const Participant(id: '', name: ''),
          )
          .name;

      await context.read<ExpenseCubit>().deleteExpense(
        widget.expense!.id,
        payerName: payerName.isNotEmpty ? payerName : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get available participants from trip
    final tripState = context.watch<TripCubit>().state;
    List<Participant> availableParticipants = [];

    if (tripState is TripLoaded) {
      final trip = tripState.trips.firstWhere(
        (t) => t.id == widget.tripId,
        orElse: () => tripState.trips.first,
      );

      // Use trip participants
      availableParticipants = trip.participants;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.expense == null
                    ? context.l10n.expenseAddTitle
                    : context.l10n.expenseEditTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),

            // Form content
            Expanded(
              child: ExpenseFormContent(
                formKey: _formKey,
                amountController: _amountController,
                descriptionController: _descriptionController,
                selectedCurrency: _selectedCurrency,
                selectedPayer: _selectedPayer,
                selectedCategory: _selectedCategory,
                selectedSplitType: _selectedSplitType,
                selectedDate: _selectedDate,
                participants: _participants,
                availableParticipants: availableParticipants,
                isEditMode: widget.expense != null,
                onCurrencyChanged: (value) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                },
                onPayerChanged: (value) {
                  setState(() {
                    _selectedPayer = value;
                  });
                },
                onCategoryChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                onSplitTypeChanged: (value) async {
                  debugPrint(
                    '🟣 [BottomSheet Handler] onSplitTypeChanged called with: $value',
                  );
                  // Handle itemized split type by navigating to wizard
                  if (value == SplitType.itemized) {
                    debugPrint('🔵 [BottomSheet] ITEMIZED BUTTON PRESSED');
                    debugPrint('🔵 [BottomSheet] Trip ID: ${widget.tripId}');
                    debugPrint(
                      '🔵 [BottomSheet] Participants: ${availableParticipants.map((p) => p.id).toList()}',
                    );
                    debugPrint('🔵 [BottomSheet] Payer: $_selectedPayer');
                    debugPrint('🔵 [BottomSheet] Currency: $_selectedCurrency');

                    // Capture navigator, messenger, and l10n before async operation
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final l10n = context.l10n;
                    debugPrint('🔵 [BottomSheet] Navigator captured');

                    try {
                      debugPrint(
                        '🔵 [BottomSheet] Creating ItemizedExpenseCubit...',
                      );
                      final expenseRepository = context
                          .read<ExpenseRepository>();
                      debugPrint(
                        '🔵 [BottomSheet] ExpenseRepository obtained: ${expenseRepository.runtimeType}',
                      );

                      debugPrint('🔵 [BottomSheet] Pushing wizard route...');
                      // Navigate to itemized expense wizard
                      final result = await navigator.push<bool>(
                        MaterialPageRoute(
                          builder: (context) {
                            debugPrint(
                              '🔵 [BottomSheet] Building wizard widget...',
                            );
                            return BlocProvider(
                              create: (context) {
                                debugPrint(
                                  '🔵 [BottomSheet] Creating cubit in BlocProvider...',
                                );
                                return ItemizedExpenseCubit(
                                  expenseRepository: expenseRepository,
                                );
                              },
                              child: ItemizedExpenseWizard(
                                tripId: widget.tripId,
                                participants: availableParticipants
                                    .map((p) => p.id)
                                    .toList(),
                                participantNames: {
                                  for (var p in availableParticipants)
                                    p.id: p.name,
                                },
                                initialPayerUserId: _selectedPayer,
                                currency: _selectedCurrency,
                              ),
                            );
                          },
                        ),
                      );

                      debugPrint(
                        '🔵 [BottomSheet] Wizard returned with result: $result',
                      );

                      // Only pop bottom sheet if wizard saved successfully
                      if (mounted && result == true) {
                        debugPrint(
                          '🔵 [BottomSheet] Wizard saved successfully - closing bottom sheet',
                        );
                        navigator.pop();
                      } else if (mounted) {
                        debugPrint(
                          '🔵 [BottomSheet] Wizard cancelled or failed - keeping bottom sheet open',
                        );
                      } else {
                        debugPrint('🔵 [BottomSheet] Widget no longer mounted');
                      }
                    } catch (e, stackTrace) {
                      debugPrint(
                        '🔴 [BottomSheet] ERROR in itemized navigation: $e',
                      );
                      debugPrint('🔴 [BottomSheet] Stack trace: $stackTrace');
                      if (!mounted) return;
                      final errorMessage = l10n.expenseItemizedOpenError(
                        e.toString(),
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    // Handle equal/weighted split types normally
                    setState(() {
                      _selectedSplitType = value;
                      // Reset participants when changing split type
                      if (value == SplitType.equal) {
                        _participants = {
                          for (var id in _participants.keys) id: 1,
                        };
                      }
                    });
                  }
                },
                onDateChanged: (value) {
                  setState(() {
                    _selectedDate = value;
                  });
                },
                onParticipantsChanged: (value) {
                  setState(() {
                    _participants = value;
                  });
                },
                onSubmit: () => _submitForm(availableParticipants),
                onDelete: widget.expense != null
                    ? () => _deleteExpense(availableParticipants)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
