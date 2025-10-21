import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';
import '../cubits/expense_cubit.dart';
import '../widgets/participant_selector.dart';
import '../../../categories/presentation/widgets/category_selector.dart';
import '../../../trips/presentation/cubits/trip_cubit.dart';
import '../../../trips/presentation/cubits/trip_state.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/utils/currency_input_formatter.dart';

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
    }
    // For new expenses, defaults will be set in build method when trip participants are available
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, tripState) {
          // Get trip participants
          List<Participant> tripParticipants = [];

          if (tripState is TripLoaded) {
            final trip = tripState.trips.firstWhere(
              (t) => t.id == widget.tripId,
              orElse: () => tripState.selectedTrip!,
            );
            tripParticipants = trip.participants;
          }

          // Show error if no participants configured
          if (tripParticipants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No participants configured',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please add participants to this trip first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initialize defaults if needed (only for new expenses)
          if (widget.expense == null && _selectedPayer == null && tripParticipants.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedPayer = tripParticipants.first.id;
                  _participants = {tripParticipants.first.id: 1};
                });
              }
            });
          }

          return ExpenseFormContent(
            formKey: _formKey,
            amountController: _amountController,
            descriptionController: _descriptionController,
            selectedCurrency: _selectedCurrency,
            selectedPayer: _selectedPayer,
            selectedCategory: _selectedCategory,
            selectedSplitType: _selectedSplitType,
            selectedDate: _selectedDate,
            participants: _participants,
            availableParticipants: tripParticipants,
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
          );
        },
      ),
    );
  }
}

/// Shared form content widget used by both page and bottom sheet
class ExpenseFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final CurrencyCode selectedCurrency;
  final String? selectedPayer;
  final String? selectedCategory;
  final SplitType selectedSplitType;
  final DateTime selectedDate;
  final Map<String, num> participants;
  final List<Participant> availableParticipants;
  final bool isEditMode;
  final ValueChanged<CurrencyCode> onCurrencyChanged;
  final ValueChanged<String?> onPayerChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<SplitType> onSplitTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<Map<String, num>> onParticipantsChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onDelete;

  const ExpenseFormContent({
    required this.formKey,
    required this.amountController,
    required this.descriptionController,
    required this.selectedCurrency,
    required this.selectedPayer,
    required this.selectedCategory,
    required this.selectedSplitType,
    required this.selectedDate,
    required this.participants,
    required this.availableParticipants,
    required this.isEditMode,
    required this.onCurrencyChanged,
    required this.onPayerChanged,
    required this.onCategoryChanged,
    required this.onSplitTypeChanged,
    required this.onDateChanged,
    required this.onParticipantsChanged,
    required this.onSubmit,
    this.onDelete,
    super.key,
  });

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing1),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        children: [
          // Section 1: AMOUNT & CURRENCY
          _buildSectionHeader(context, 'AMOUNT & CURRENCY'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount field
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: amountController,
                  label: 'Amount',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    try {
                      final cleanValue = stripCurrencyFormatting(value);
                      final amount = Decimal.parse(cleanValue);
                      if (amount <= Decimal.zero) {
                        return 'Must be > 0';
                      }
                    } catch (e) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacing1),
              // Currency selector
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<CurrencyCode>(
                  initialValue: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                  ),
                  items: CurrencyCode.values.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency.code),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onCurrencyChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 2: WHAT WAS IT FOR?
          _buildSectionHeader(context, 'WHAT WAS IT FOR?'),
          CustomTextField(
            controller: descriptionController,
            label: 'Description (optional)',
            maxLength: 200,
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 3: CATEGORY
          CategorySelector(
            selectedCategoryId: selectedCategory,
            onCategoryChanged: onCategoryChanged,
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 4: WHO PAID & WHEN?
          _buildSectionHeader(context, 'WHO PAID & WHEN?'),
          Row(
            children: [
              // Payer selector
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedPayer,
                  decoration: const InputDecoration(
                    labelText: 'Payer',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: availableParticipants.map((participant) {
                    return DropdownMenuItem(
                      value: participant.id,
                      child: Text(participant.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    onPayerChanged(value);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacing1),
              // Date selector
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      onDateChanged(date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(selectedDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 5: HOW TO SPLIT?
          _buildSectionHeader(context, 'HOW TO SPLIT?'),
          SegmentedButton<SplitType>(
            segments: const [
              ButtonSegment(
                value: SplitType.equal,
                label: Text('Split Equally'),
                icon: Icon(Icons.people),
              ),
              ButtonSegment(
                value: SplitType.weighted,
                label: Text('By Weight'),
                icon: Icon(Icons.balance),
              ),
            ],
            selected: {selectedSplitType},
            onSelectionChanged: (Set<SplitType> newSelection) {
              onSplitTypeChanged(newSelection.first);
            },
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Section 6: Participants
          ParticipantSelector(
            splitType: selectedSplitType,
            selectedParticipants: participants,
            onParticipantsChanged: onParticipantsChanged,
            availableParticipants: availableParticipants,
          ),

          const SizedBox(height: AppTheme.spacing3),
          const Divider(),
          const SizedBox(height: AppTheme.spacing2),

          // Submit button
          CustomButton(
            text: isEditMode ? 'Save Changes' : 'Add Expense',
            onPressed: onSubmit,
          ),

          // Delete button (only in edit mode)
          if (isEditMode && onDelete != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
              label: const Text('Delete Expense'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
