import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/itemized_expense_cubit.dart';
import '../../../cubits/itemized_expense_state.dart';
import '../../../../../../core/l10n/l10n_extensions.dart';

/// Step 1: Select participants and payer
class PeopleStepPage extends StatelessWidget {
  final List<String> participants;
  final Map<String, String> participantNames;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const PeopleStepPage({
    super.key,
    required this.participants,
    required this.participantNames,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemizedExpenseCubit, ItemizedExpenseState>(
      builder: (context, state) {
        final payerUserId = _getPayerUserId(state);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.receiptSplitPeopleTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: payerUserId == null
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                payerUserId == null
                    ? context.l10n.receiptSplitPeopleDescriptionError
                    : context.l10n.receiptSplitPeopleDescription,
                style: TextStyle(
                  color: payerUserId == null
                      ? Theme.of(context).colorScheme.error
                      : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final userId = participants[index];
                    final name = participantNames[userId] ?? userId;
                    final isSelected = payerUserId == userId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : Icon(
                                Icons.radio_button_unchecked,
                                color: Colors.grey.shade400,
                              ),
                        onTap: () {
                          // Update payer in cubit
                          context.read<ItemizedExpenseCubit>().setPayer(userId);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(context.l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: payerUserId != null ? onContinue : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        context.l10n.receiptSplitPeopleContinueButton,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String? _getPayerUserId(ItemizedExpenseState state) {
    if (state is ItemizedExpenseEditing) {
      return state.payerUserId;
    } else if (state is ItemizedExpenseCalculating) {
      return state.draft.payerUserId;
    } else if (state is ItemizedExpenseReady) {
      return state.draft.payerUserId;
    }
    return null;
  }
}
