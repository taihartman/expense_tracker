import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';
import '../cubits/expense_cubit.dart';
import '../pages/expense_form_page.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/models/participant.dart';
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
    builder: (context) => ExpenseFormBottomSheet(
      tripId: tripId,
      expense: expense,
    ),
  );
}

/// Bottom sheet widget for expense form
class ExpenseFormBottomSheet extends StatefulWidget {
  final String tripId;
  final Expense? expense;

  const ExpenseFormBottomSheet({
    required this.tripId,
    this.expense,
    super.key,
  });

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

    if (tripState is TripLoaded) {
      final trip = tripState.trips.firstWhere(
        (t) => t.id == widget.tripId,
        orElse: () => tripState.trips.first,
      );

      // Use trip participants
      availableParticipants = trip.participants;
    }

    if (widget.expense != null) {
      // Editing existing expense - format the amount with commas
      final formatter = NumberFormat('#,##0.##', 'en_US');
      _amountController.text = formatter.format(widget.expense!.amount.toDouble());
      _descriptionController.text = widget.expense!.description ?? '';
      _selectedCurrency = widget.expense!.currency;
      _selectedPayer = widget.expense!.payerUserId;
      _selectedSplitType = widget.expense!.splitType;
      _selectedDate = widget.expense!.date;
      _participants = Map.from(widget.expense!.participants);
      _selectedCategory = widget.expense!.categoryId;
    } else {
      // New expense - default to first available participant
      if (availableParticipants.isNotEmpty) {
        _selectedPayer = availableParticipants.first.id;
        _participants = {availableParticipants.first.id: 1};
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPayer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a payer')),
        );
        return;
      }

      if (_participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one participant')),
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
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        categoryId: _selectedCategory,
        splitType: _selectedSplitType,
        participants: _participants,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.expense != null) {
        // Update existing expense
        context.read<ExpenseCubit>().updateExpense(expense);
      } else {
        // Create new expense
        context.read<ExpenseCubit>().createExpense(expense);
      }

      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteExpense() async {
    if (widget.expense == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ExpenseCubit>().deleteExpense(widget.expense!.id);
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
                widget.expense == null ? 'Add Expense' : 'Edit Expense',
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
                onSplitTypeChanged: (value) {
                  setState(() {
                    _selectedSplitType = value;
                    // Reset participants when changing split type
                    if (value == SplitType.equal) {
                      _participants = {
                        for (var id in _participants.keys) id: 1,
                      };
                    }
                  });
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
                onSubmit: _submitForm,
                onDelete: widget.expense != null ? _deleteExpense : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
