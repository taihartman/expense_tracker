import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/itemized_expense_cubit.dart';
import '../../cubits/itemized_expense_state.dart';
import '../../../domain/models/expense.dart';
import '../../../../../core/models/currency_code.dart';
import '../../../../../core/l10n/l10n_extensions.dart';
import 'steps/people_step_page.dart';
import 'steps/items_step_page.dart';
import 'steps/extras_step_page.dart';
import 'steps/review_step_page.dart';

/// 4-step wizard for creating/editing itemized expenses
///
/// Steps:
/// 1. People - Select participants and payer
/// 2. Items - Add line items and assign to people
/// 3. Extras - Configure tax, tip, fees, discounts
/// 4. Review - Review breakdown and save
class ItemizedExpenseWizard extends StatefulWidget {
  final String tripId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? initialPayerUserId;
  final CurrencyCode currency;
  final Expense? existingExpense; // For edit mode

  const ItemizedExpenseWizard({
    super.key,
    required this.tripId,
    required this.participants,
    required this.participantNames,
    this.initialPayerUserId,
    required this.currency,
    this.existingExpense,
  });

  @override
  State<ItemizedExpenseWizard> createState() => _ItemizedExpenseWizardState();
}

class _ItemizedExpenseWizardState extends State<ItemizedExpenseWizard> {
  int _currentStep = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final isEditMode = widget.existingExpense != null;
    debugPrint(
      '🟢 [Wizard] ItemizedExpenseWizard initState (${isEditMode ? "EDIT" : "CREATE"} mode)',
    );
    debugPrint('🟢 [Wizard] Trip ID: ${widget.tripId}');
    debugPrint('🟢 [Wizard] Participants: ${widget.participants}');

    if (isEditMode) {
      // Edit mode - load existing expense data
      debugPrint(
        '🟢 [Wizard] Edit mode - loading expense: ${widget.existingExpense!.id}',
      );
      context.read<ItemizedExpenseCubit>().initFromExpense(
        expense: widget.existingExpense!,
        participants: widget.participants,
      );
      debugPrint('🟢 [Wizard] initFromExpense() completed');
    } else {
      // Create mode - start with empty state
      debugPrint('🟢 [Wizard] Create mode - initializing new expense');
      debugPrint('🟢 [Wizard] Payer: ${widget.initialPayerUserId}');
      debugPrint('🟢 [Wizard] Currency: ${widget.currency}');
      context.read<ItemizedExpenseCubit>().init(
        tripId: widget.tripId,
        participants: widget.participants,
        payerUserId: widget.initialPayerUserId,
        currency: widget.currency,
      );
      debugPrint('🟢 [Wizard] init() completed');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onStepTapped(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingExpense != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? context.l10n.receiptSplitWizardTitleEdit
              : context.l10n.receiptSplitWizardTitleNew,
        ),
        elevation: 0,
      ),
      body: BlocConsumer<ItemizedExpenseCubit, ItemizedExpenseState>(
        listener: (context, state) {
          if (state is ItemizedExpenseSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditMode
                      ? context.l10n.receiptSplitWizardUpdatedSuccess
                      : context.l10n.receiptSplitWizardSavedSuccess,
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Return true to indicate successful save
            Navigator.of(context).pop(true);
          } else if (state is ItemizedExpenseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ItemizedExpenseSaving) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.l10n.receiptSplitWizardSaving),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildStepper(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PeopleStepPage(
                      participants: widget.participants,
                      participantNames: widget.participantNames,
                      onContinue: _onStepContinue,
                      onCancel: _onStepCancel,
                    ),
                    ItemsStepPage(
                      participantNames: widget.participantNames,
                      onContinue: _onStepContinue,
                      onBack: _onStepCancel,
                    ),
                    ExtrasStepPage(
                      onContinue: _onStepContinue,
                      onBack: _onStepCancel,
                    ),
                    ReviewStepPage(
                      participantNames: widget.participantNames,
                      currency: widget.currency,
                      onBack: _onStepCancel,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(
            0,
            context.l10n.receiptSplitWizardStepPeople,
            Icons.people,
          ),
          _buildStepConnector(0),
          _buildStepIndicator(
            1,
            context.l10n.receiptSplitWizardStepItems,
            Icons.receipt_long,
          ),
          _buildStepConnector(1),
          _buildStepIndicator(
            2,
            context.l10n.receiptSplitWizardStepExtras,
            Icons.add_circle_outline,
          ),
          _buildStepConnector(2),
          _buildStepIndicator(
            3,
            context.l10n.receiptSplitWizardStepReview,
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    final canTap = step <= _currentStep;

    return Expanded(
      child: GestureDetector(
        onTap: canTap ? () => _onStepTapped(step) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : isCompleted
                    ? Colors.green
                    : Colors.grey.shade300,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isActive || isCompleted
                    ? Colors.white
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : isCompleted
                    ? Colors.green
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
}
