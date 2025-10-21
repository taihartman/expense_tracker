import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';
import '../../../../core/constants/participants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

/// Card widget displaying expense details
///
/// Shows amount, description, payer, date, split type, and participants
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({
    required this.expense,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shares = expense.calculateShares();
    final sharePerPerson = shares.values.first; // For equal split display

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount and category row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Amount
                  Text(
                    Formatters.formatCurrency(expense.amount, expense.currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Category icon (if available)
                  if (expense.categoryId != null)
                    Icon(
                      _getCategoryIcon(expense.categoryId!),
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing1),

              // Description
              if (expense.description != null && expense.description!.isNotEmpty)
                Text(
                  expense.description!,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: AppTheme.spacing1),

              // Payer and date row
              Row(
                children: [
                  // Payer
                  Text(
                    'Paid by ${Participants.getNameById(expense.payerUserId)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  // Date
                  Text(
                    DateFormat('MMM dd, yyyy').format(expense.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing1),

              // Split info row
              Row(
                children: [
                  // Split type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing1,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      expense.splitType.name == 'equal' ? 'Equal split' : 'Weighted split',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  // Participant count
                  Text(
                    '${expense.participants.length} participants',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing1),

              // Share per person (for equal split)
              if (expense.splitType.name == 'equal')
                Text(
                  '${Formatters.formatCurrency(sharePerPerson, expense.currency)} per person',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'meals':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'activities':
        return Icons.attractions;
      case 'shopping':
        return Icons.shopping_cart;
      default:
        return Icons.more_horiz;
    }
  }
}
