import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../cubits/expense_cubit.dart';
import '../cubits/itemized_expense_cubit.dart';
import '../widgets/participant_selector.dart';
import '../../../categories/presentation/widgets/category_selector.dart';
import '../../../trips/presentation/cubits/trip_cubit.dart';
import '../../../trips/presentation/cubits/trip_state.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/currency_text_field.dart';
import '../../../../shared/utils/currency_input_formatter.dart';
import 'itemized/itemized_expense_wizard.dart';
import '../../../../core/services/activity_logger_service.dart';

/// Page for creating or editing an expense
class ExpenseFormPage extends StatefulWidget {
  final String tripId;
  final Expense? expense; // null for create, populated for edit

  const ExpenseFormPage({required this.tripId, this.expense, super.key});

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
      _amountController.text = formatAmountForInput(
        widget.expense!.amount,
        widget.expense!.currency,
      );
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

  Future<void> _submitForm(List<Participant> tripParticipants) async {
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

      // Get current user for activity logging
      final currentUser = await context.read<TripCubit>().getCurrentUserForTrip(
        widget.tripId,
      );
      final actorName = currentUser?.name;

      if (widget.expense != null) {
        // Update existing expense
        context.read<ExpenseCubit>().updateExpense(
          expense,
          actorName: actorName,
        );
      } else {
        // Create new expense
        context.read<ExpenseCubit>().createExpense(
          expense,
          actorName: actorName,
        );
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expense == null
              ? context.l10n.expenseAddTitle
              : context.l10n.expenseEditTitle,
        ),
      ),
      body: BlocBuilder<TripCubit, TripState>(
        builder: (context, tripState) {
          // Get trip participants and allowed currencies
          List<Participant> tripParticipants = [];
          List<CurrencyCode> tripAllowedCurrencies = [CurrencyCode.usd];

          CurrencyCode? tripBaseCurrency;

          if (tripState is TripLoaded) {
            final trip = tripState.trips.firstWhere(
              (t) => t.id == widget.tripId,
              orElse: () => tripState.selectedTrip!,
            );
            tripParticipants = trip.participants;
            tripBaseCurrency = trip.defaultCurrency;
            tripAllowedCurrencies = trip.allowedCurrencies;
          }

          // Show error if no participants configured
          if (tripParticipants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.expenseNoParticipantsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.expenseNoParticipantsDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: Text(context.l10n.expenseGoBackButton),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initialize currency default for new expenses
          if (widget.expense == null &&
              tripBaseCurrency != null &&
              _selectedCurrency == CurrencyCode.usd) {
            final baseCurrency =
                tripBaseCurrency; // Capture for use in callback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  // Set currency to trip's base currency for new expenses
                  _selectedCurrency = baseCurrency;
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
            allowedCurrencies:
                tripAllowedCurrencies, // T023: Pass allowed currencies
            isEditMode: widget.expense != null,
            tripId: widget.tripId,
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
              debugPrint('🟣 [Handler] onSplitTypeChanged called with: $value');
              // Handle itemized split type by navigating to wizard
              if (value == SplitType.itemized) {
                debugPrint('🔵 [ExpenseForm] ITEMIZED BUTTON PRESSED');
                debugPrint('🔵 [ExpenseForm] Trip ID: ${widget.tripId}');
                debugPrint(
                  '🔵 [ExpenseForm] Participants: ${tripParticipants.map((p) => p.id).toList()}',
                );
                debugPrint('🔵 [ExpenseForm] Payer: $_selectedPayer');
                debugPrint('🔵 [ExpenseForm] Currency: $_selectedCurrency');

                // Capture navigator and context before async operation
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final l10n = context.l10n;
                debugPrint('🔵 [ExpenseForm] Navigator captured');

                try {
                  debugPrint(
                    '🔵 [ExpenseForm] Creating ItemizedExpenseCubit...',
                  );
                  final expenseRepository = context.read<ExpenseRepository>();
                  final activityLoggerService = context
                      .read<ActivityLoggerService>();
                  debugPrint(
                    '🔵 [ExpenseForm] ExpenseRepository obtained: ${expenseRepository.runtimeType}',
                  );

                  debugPrint('🔵 [ExpenseForm] Pushing wizard route...');
                  // Navigate to itemized expense wizard
                  final result = await navigator.push<bool>(
                    MaterialPageRoute(
                      builder: (context) {
                        debugPrint(
                          '🔵 [ExpenseForm] Building wizard widget...',
                        );
                        return BlocProvider(
                          create: (context) {
                            debugPrint(
                              '🔵 [ExpenseForm] Creating cubit in BlocProvider...',
                            );
                            return ItemizedExpenseCubit(
                              expenseRepository: expenseRepository,
                              activityLoggerService: activityLoggerService,
                            );
                          },
                          child: ItemizedExpenseWizard(
                            tripId: widget.tripId,
                            participants: tripParticipants
                                .map((p) => p.id)
                                .toList(),
                            participantNames: {
                              for (var p in tripParticipants) p.id: p.name,
                            },
                            initialPayerUserId: _selectedPayer,
                            currency: _selectedCurrency,
                            allowedCurrencies: tripAllowedCurrencies,
                          ),
                        );
                      },
                    ),
                  );

                  debugPrint(
                    '🔵 [ExpenseForm] Wizard returned with result: $result',
                  );

                  // Only pop expense form if wizard saved successfully
                  if (mounted && result == true) {
                    debugPrint(
                      '🔵 [ExpenseForm] Wizard saved successfully - closing expense form',
                    );
                    navigator.pop();
                  } else if (mounted) {
                    debugPrint(
                      '🔵 [ExpenseForm] Wizard cancelled or failed - keeping expense form open',
                    );
                  } else {
                    debugPrint('🔵 [ExpenseForm] Widget no longer mounted');
                  }
                } catch (e, stackTrace) {
                  debugPrint(
                    '🔴 [ExpenseForm] ERROR in itemized navigation: $e',
                  );
                  debugPrint('🔴 [ExpenseForm] Stack trace: $stackTrace');
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.expenseItemizedOpenError(e.toString()),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                // Handle equal/weighted split types normally
                setState(() {
                  _selectedSplitType = value;
                  // Reset participants when changing split type
                  if (value == SplitType.equal) {
                    _participants = {for (var id in _participants.keys) id: 1};
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
            onSubmit: () => _submitForm(tripParticipants),
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
  final List<CurrencyCode> allowedCurrencies; // T023: Filter currencies
  final bool isEditMode;
  final String tripId;
  final ValueChanged<CurrencyCode> onCurrencyChanged;
  final ValueChanged<String?> onPayerChanged;
  final ValueChanged<String?> onCategoryChanged;
  final Future<void> Function(SplitType) onSplitTypeChanged;
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
    required this.allowedCurrencies, // T023: Filter currencies
    required this.isEditMode,
    required this.tripId,
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
          _buildSectionHeader(
            context,
            context.l10n.expenseSectionAmountCurrency,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount field
              Expanded(
                flex: 2,
                child: Builder(
                  builder: (context) => CurrencyTextField(
                    controller: amountController,
                    currencyCode: selectedCurrency,
                    label: context.l10n.expenseFieldAmountLabel,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing1),
              // Currency selector
              Expanded(
                flex: 1,
                child: Builder(
                  builder: (context) {
                    // T023: Filter currencies to trip's allowed currencies
                    // T026: Validation - new expenses can only use allowedCurrencies,
                    // existing expenses can keep their currency (backward compatibility)
                    final availableCurrencies = [
                      ...allowedCurrencies,
                      if (isEditMode &&
                          !allowedCurrencies.contains(selectedCurrency))
                        selectedCurrency,
                    ];

                    // T026: Check if editing expense with non-allowed currency
                    final isUsingNonAllowedCurrency =
                        isEditMode &&
                        !allowedCurrencies.contains(selectedCurrency);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<CurrencyCode>(
                          initialValue: selectedCurrency,
                          decoration: InputDecoration(
                            labelText: context.l10n.expenseFieldCurrencyLabel,
                          ),
                          items: availableCurrencies.map((currency) {
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
                        // T026: Show info message for non-allowed currency
                        if (isUsingNonAllowedCurrency)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Note: ${selectedCurrency.code.toUpperCase()} is no longer in the allowed currencies',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 2: WHAT WAS IT FOR?
          _buildSectionHeader(context, context.l10n.expenseSectionDescription),
          Builder(
            builder: (context) => CustomTextField(
              controller: descriptionController,
              label: context.l10n.expenseFieldDescriptionLabel,
              maxLength: 200,
            ),
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 3: CATEGORY
          CategorySelector(
            selectedCategoryId: selectedCategory,
            onCategoryChanged: onCategoryChanged,
            tripId: tripId,
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 4: WHO PAID & WHEN?
          _buildSectionHeader(context, context.l10n.expenseSectionPayerDate),
          Row(
            children: [
              // Payer selector
              Expanded(
                child: Builder(
                  builder: (context) => DropdownButtonFormField<String>(
                    initialValue: selectedPayer,
                    decoration: InputDecoration(
                      labelText: context.l10n.expenseFieldPayerLabel,
                      prefixIcon: const Icon(Icons.person),
                      border: selectedPayer == null && !isEditMode
                          ? OutlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            )
                          : null,
                      enabledBorder: selectedPayer == null && !isEditMode
                          ? OutlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            )
                          : null,
                      helperText: selectedPayer == null && !isEditMode
                          ? context.l10n.expenseFieldPayerRequired
                          : null,
                      helperStyle: TextStyle(color: theme.colorScheme.error),
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
              ),
              const SizedBox(width: AppTheme.spacing1),
              // Date selector
              Expanded(
                child: Builder(
                  builder: (context) => InkWell(
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
                      decoration: InputDecoration(
                        labelText: context.l10n.expenseFieldDateLabel,
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),

          // Section 5: HOW TO SPLIT?
          _buildSectionHeader(context, context.l10n.expenseSectionSplit),
          Builder(
            builder: (context) => SegmentedButton<SplitType>(
              segments: [
                ButtonSegment(
                  value: SplitType.equal,
                  label: Text(context.l10n.expenseSplitTypeEqual),
                  icon: const Icon(Icons.people),
                ),
                ButtonSegment(
                  value: SplitType.weighted,
                  label: Text(context.l10n.expenseSplitTypeWeighted),
                  icon: const Icon(Icons.balance),
                ),
              ],
              selected: {
                selectedSplitType == SplitType.itemized
                    ? SplitType.equal
                    : selectedSplitType,
              },
              onSelectionChanged: (Set<SplitType> newSelection) {
                onSplitTypeChanged(newSelection.first);
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Section 6: Participants (only for equal/weighted splits)
          if (selectedSplitType != SplitType.itemized)
            ParticipantSelector(
              splitType: selectedSplitType,
              selectedParticipants: participants,
              onParticipantsChanged: onParticipantsChanged,
              availableParticipants: availableParticipants,
              showRequired: !isEditMode && participants.isEmpty,
            ),

          const SizedBox(height: AppTheme.spacing3),
          const Divider(),
          const SizedBox(height: AppTheme.spacing2),

          // Submit button
          Builder(
            builder: (context) => CustomButton(
              text: isEditMode
                  ? context.l10n.expenseSaveChangesButton
                  : context.l10n.expenseSaveButton,
              onPressed: onSubmit,
            ),
          ),

          // Delete button (only in edit mode)
          if (isEditMode && onDelete != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            Builder(
              builder: (context) => OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: Text(context.l10n.expenseDeleteButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
