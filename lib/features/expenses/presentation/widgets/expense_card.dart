import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';
import '../../../../core/models/participant.dart';
import '../../../../core/models/split_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../categories/presentation/cubit/category_state.dart';
import '../../../categories/presentation/cubit/category_customization_cubit.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../../shared/utils/category_display_helper.dart';
import '../../../../shared/utils/icon_helper.dart';

/// Card widget displaying expense details
///
/// Shows amount, description, payer, date, split type, and participants
/// Can be expanded to show detailed breakdown
class ExpenseCard extends StatefulWidget {
  final Expense expense;
  final List<Participant> participants;
  final VoidCallback? onTap;

  const ExpenseCard({
    required this.expense,
    required this.participants,
    this.onTap,
    super.key,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  bool _isExpanded = false;
  final Map<String, Category> _cachedCategories = {};

  String _getParticipantName(String userId) {
    try {
      return widget.participants.firstWhere((p) => p.id == userId).name;
    } catch (e) {
      return userId; // Fallback to ID if not found
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expense = widget.expense;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed summary
          InkWell(
            onTap: widget.onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                        Formatters.formatCurrency(
                          expense.amount,
                          expense.currency,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Category icon with customization support (if available)
                      if (expense.categoryId != null)
                        _buildCategoryIcon(context, expense.categoryId!)
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing1),

                  // Description
                  if (expense.description != null &&
                      expense.description!.isNotEmpty)
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
                        context.l10n.expensePaidBy(
                          _getParticipantName(expense.payerUserId),
                        ),
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

                  // Split info row with expansion toggle
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
                          expense.splitType.displayName(context),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing1),
                      // Participant count
                      Text(
                        context.l10n.expenseParticipantCount(
                          expense.participants.length,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      // Expansion toggle
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        tooltip: _isExpanded
                            ? context.l10n.expenseShowLess
                            : context.l10n.expenseShowDetails,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded details section
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: _buildExpandedContent(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    final expense = widget.expense;

    if (expense.splitType == SplitType.itemized) {
      return _buildItemizedDetails();
    } else {
      return _buildEqualWeightedDetails();
    }
  }

  Widget _buildItemizedDetails() {
    final expense = widget.expense;
    final theme = Theme.of(context);

    if (expense.items == null || expense.items!.isEmpty) {
      return Text(
        context.l10n.expenseCardNoItemizedDetails,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Items Section
        Text(
          context.l10n.expenseCardLineItemsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing1),
        ...expense.items!.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Show assigned users
                      if (item.assignment.users.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: item.assignment.users.map((userId) {
                            return Chip(
                              label: Text(
                                _getParticipantName(userId),
                                style: theme.textTheme.labelSmall,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacing1),
                Text(
                  '${item.quantity.toString()} × ${Formatters.formatCurrency(item.unitPrice, expense.currency)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Extras Section (Tax, Tip, Fees)
        if (expense.extras != null &&
            (expense.extras!.tax != null ||
                expense.extras!.tip != null ||
                expense.extras!.fees.isNotEmpty)) ...[
          const SizedBox(height: AppTheme.spacing2),
          const Divider(),
          const SizedBox(height: AppTheme.spacing1),
          Text(
            context.l10n.expenseCardExtrasTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing1),
          if (expense.extras!.tax != null)
            _buildExtraRow(
              context.l10n.expenseCardExtrasTaxLabel,
              expense.extras!.tax!.type == 'percent'
                  ? '${expense.extras!.tax!.value}%'
                  : Formatters.formatCurrency(
                      expense.extras!.tax!.value,
                      expense.currency,
                    ),
              theme,
            ),
          if (expense.extras!.tip != null)
            _buildExtraRow(
              context.l10n.expenseCardExtrasTipLabel,
              expense.extras!.tip!.type == 'percent'
                  ? '${expense.extras!.tip!.value}%'
                  : Formatters.formatCurrency(
                      expense.extras!.tip!.value,
                      expense.currency,
                    ),
              theme,
            ),
          ...expense.extras!.fees.map(
            (fee) => _buildExtraRow(
              fee.name,
              fee.type == 'percent'
                  ? '${fee.value}%'
                  : Formatters.formatCurrency(fee.value, expense.currency),
              theme,
            ),
          ),
        ],

        // Per-Person Breakdown
        if (expense.participantBreakdown != null &&
            expense.participantBreakdown!.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing2),
          const Divider(),
          const SizedBox(height: AppTheme.spacing1),
          Text(
            context.l10n.expenseCardPerPersonBreakdown,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing1),
          ...expense.participantBreakdown!.entries.map((entry) {
            final breakdown = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          _getParticipantName(entry.key)[0].toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing1),
                      Text(
                        _getParticipantName(entry.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(
                      breakdown.total,
                      expense.currency,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEqualWeightedDetails() {
    final expense = widget.expense;
    final theme = Theme.of(context);
    final shares = expense.calculateShares();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.expenseCardPerPersonBreakdown,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing1),
        ...shares.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _getParticipantName(entry.key)[0].toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing1),
                    Text(
                      _getParticipantName(entry.key),
                      style: theme.textTheme.bodyMedium,
                    ),
                    // Show weight for weighted split
                    if (expense.splitType == SplitType.weighted) ...[
                      const SizedBox(width: AppTheme.spacing1),
                      Text(
                        '(${expense.participants[entry.key]}x)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  Formatters.formatCurrency(entry.value, expense.currency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExtraRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders category icon with customization support
  Widget _renderCategoryIcon({
    required Category category,
    required CategoryCustomizationCubit? customizationCubit,
  }) {
    final customization = customizationCubit?.getCustomization(category.id);
    final displayCategory = DisplayCategory.fromGlobalAndCustomization(
      globalCategory: category,
      customization: customization,
    );

    final iconData = IconHelper.getIconData(displayCategory.icon);
    final color = _parseColor(displayCategory.color);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 20,
      ),
    );
  }

  /// Builds category icon with customization support
  /// Fetches missing categories on-demand to ensure icons always display
  Widget _buildCategoryIcon(BuildContext context, String categoryId) {
    final categoryCubit = context.read<CategoryCubit>();
    final categoryState = categoryCubit.state;
    final customizationCubit = context.read<CategoryCustomizationCubit?>();

    // Check if category is in top categories loaded by cubit
    if (categoryState is CategoryTopLoaded) {
      final category = categoryState.categories
          .where((c) => c.id == categoryId)
          .firstOrNull;

      if (category != null) {
        return _renderCategoryIcon(
          category: category,
          customizationCubit: customizationCubit,
        );
      }
    }

    // Check cache for previously fetched category
    if (_cachedCategories.containsKey(categoryId)) {
      return _renderCategoryIcon(
        category: _cachedCategories[categoryId]!,
        customizationCubit: customizationCubit,
      );
    }

    // Fallback: Fetch the specific category
    return FutureBuilder<Category?>(
      future: context.read<CategoryRepository>().getCategoryById(categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while fetching
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Cache the fetched category
          _cachedCategories[categoryId] = snapshot.data!;
          return _renderCategoryIcon(
            category: snapshot.data!,
            customizationCubit: customizationCubit,
          );
        }

        // Ultimate fallback: Show generic icon
        final theme = Theme.of(context);
        return Icon(
          Icons.category,
          color: theme.colorScheme.primary,
        );
      },
    );
  }

  /// Parses hex color string to Color
  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
