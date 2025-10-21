import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../../domain/models/expense.dart';
import '../cubits/expense_cubit.dart';
import '../widgets/participant_selector.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/constants/participants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Page for creating or editing an expense
class ExpenseFormPage extends StatefulWidget {
  final String tripId;
  final Expense? expense; // null for create, populated for edit

  const ExpenseFormPage({
    required this.tripId,
    this.expense,
    super.key,
  });

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
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
    
    if (widget.expense != null) {
      // Editing existing expense
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description ?? '';
      _selectedCurrency = widget.expense!.currency;
      _selectedPayer = widget.expense!.payerUserId;
      _selectedSplitType = widget.expense!.splitType;
      _selectedDate = widget.expense!.date;
      _participants = Map.from(widget.expense!.participants);
      _selectedCategory = widget.expense!.categoryId;
    } else {
      // New expense - default to first participant
      _selectedPayer = Participants.all.first.id;
      // Default participants for equal split
      _participants = {Participants.all.first.id: 1};
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
        amount: Decimal.parse(_amountController.text),
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        categoryId: _selectedCategory,
        splitType: _selectedSplitType,
        participants: _participants,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<ExpenseCubit>().createExpense(expense);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          children: [
            // Amount field
            CustomTextField(
              controller: _amountController,
              label: 'Amount',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                try {
                  final amount = Decimal.parse(value);
                  if (amount <= Decimal.zero) {
                    return 'Amount must be greater than 0';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Description field
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLength: 200,
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Currency selector
            DropdownButtonFormField<CurrencyCode>(
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Currency',
              ),
              items: CurrencyCode.values.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Payer selector
            DropdownButtonFormField<String>(
              initialValue: _selectedPayer,
              decoration: const InputDecoration(
                labelText: 'Payer',
              ),
              items: Participants.all.map((participant) {
                return DropdownMenuItem(
                  value: participant.id,
                  child: Text(participant.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPayer = value;
                });
              },
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Split type selector
            DropdownButtonFormField<SplitType>(
              initialValue: _selectedSplitType,
              decoration: const InputDecoration(
                labelText: 'Split Type',
              ),
              items: SplitType.values.map((splitType) {
                return DropdownMenuItem(
                  value: splitType,
                  child: Text(
                    splitType.name == 'equal' ? 'Equal Split' : 'Weighted Split',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
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
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Date selector
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing2),

            // Participants section
            ParticipantSelector(
              splitType: _selectedSplitType,
              selectedParticipants: _participants,
              onParticipantsChanged: (updatedParticipants) {
                setState(() {
                  _participants = updatedParticipants;
                });
              },
            ),

            const SizedBox(height: AppTheme.spacing3),

            // Submit button
            CustomButton(
              text: widget.expense == null ? 'Create Expense' : 'Update Expense',
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
