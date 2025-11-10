import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../../../cubits/itemized_expense_cubit.dart';
import '../../../cubits/itemized_expense_state.dart';
import '../../../../../../core/models/currency_code.dart';
import '../../../../../../core/l10n/l10n_extensions.dart';
import '../../../../../trips/presentation/cubits/trip_cubit.dart';

/// Step 4: Review breakdown and save
class ReviewStepPage extends StatelessWidget {
  final Map<String, String> participantNames;
  final CurrencyCode currency;
  final VoidCallback onBack;

  const ReviewStepPage({
    super.key,
    required this.participantNames,
    required this.currency,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemizedExpenseCubit, ItemizedExpenseState>(
      builder: (context, state) {
        if (state is ItemizedExpenseCalculating) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Calculating...'),
              ],
            ),
          );
        }

        if (state is! ItemizedExpenseReady) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Please add items and assign them'),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: onBack, child: const Text('Go Back')),
              ],
            ),
          );
        }

        final validationErrors = state.draft.validationErrors;
        final validationWarnings = state.draft.validationWarnings;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.receiptSplitReviewTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.receiptSplitReviewDescription,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (validationErrors.isNotEmpty)
                _buildErrorBanner(context, validationErrors),
              if (state.draft.expectedSubtotal != null)
                _buildSubtotalMismatchWarning(context, state),
              if (validationWarnings.isNotEmpty)
                _buildWarningBanner(context, validationWarnings),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSummaryCard(context, state),
                      const SizedBox(height: 16),
                      _buildBreakdownList(context, state),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildNavigationButtons(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(BuildContext context, List<String> errors) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.receiptSplitReviewCannotSaveTitle,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                '• $error',
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context, List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.receiptSplitReviewWarningTitle,
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                '• $warning',
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ItemizedExpenseReady state) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              context.l10n.receiptSplitReviewGrandTotal,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '${currency.symbol}${state.grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.receiptSplitReviewPeopleSplitting(
                state.participantBreakdown.length,
              ),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownList(BuildContext context, ItemizedExpenseReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.receiptSplitReviewPerPersonBreakdown,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...state.participantBreakdown.entries.map((entry) {
          final name = participantNames[entry.key] ?? entry.key;
          final breakdown = entry.value;
          final isPayer = state.draft.payerUserId == entry.key;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isPayer) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.l10n.receiptSplitReviewPaidBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${currency.symbol}${breakdown.total.toStringAsFixed(2)}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreakdownRow(
                        context.l10n.receiptSplitReviewItemsSubtotal,
                        breakdown.itemsSubtotal,
                        currency,
                      ),
                      ...breakdown.extrasAllocated.entries.map((extra) {
                        final label = _formatExtraLabel(extra.key);
                        return _buildBreakdownRow(label, extra.value, currency);
                      }),
                      if (breakdown.roundedAdjustment != Decimal.zero)
                        _buildBreakdownRow(
                          context.l10n.receiptSplitReviewRounding,
                          breakdown.roundedAdjustment,
                          currency,
                        ),
                      const Divider(height: 24),
                      _buildBreakdownRow(
                        context.l10n.receiptSplitReviewTotal,
                        breakdown.total,
                        currency,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        title: Text(
                          context.l10n.receiptSplitReviewItemDetails,
                          style: const TextStyle(fontSize: 14),
                        ),
                        children: breakdown.items.map((item) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.itemName,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${item.quantity} × ${currency.symbol}${item.unitPrice} × ${(item.assignedShare * Decimal.fromInt(100)).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '${currency.symbol}${item.contributionAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBreakdownRow(
    String label,
    Decimal amount,
    CurrencyCode curr, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '${curr.symbol}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ItemizedExpenseReady state,
  ) {
    final canSave = state.canSave;
    final isEditMode = state.draft.isEditMode;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(context.l10n.commonBack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: canSave
                ? () async {
                    // Get current user for activity logging
                    final currentUser = await context
                        .read<TripCubit>()
                        .getCurrentUserForTrip(state.draft.tripId);
                    final actorName = currentUser?.name;

                    // Save with actor name for activity logging
                    context.read<ItemizedExpenseCubit>().save(
                      actorName: actorName,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
            ),
            icon: const Icon(Icons.save),
            label: Text(
              isEditMode
                  ? context.l10n.receiptSplitReviewUpdateButton
                  : context.l10n.receiptSplitReviewSaveButton,
            ),
          ),
        ),
      ],
    );
  }

  String _formatExtraLabel(String key) {
    if (key == 'tax') return 'Tax';
    if (key == 'tip') return 'Tip';
    if (key.startsWith('fee_')) return key.substring(4);
    if (key.startsWith('discount_')) return key.substring(9);
    return key;
  }

  Widget _buildSubtotalMismatchWarning(
    BuildContext context,
    ItemizedExpenseReady state,
  ) {
    final expectedSubtotal = state.draft.expectedSubtotal;
    if (expectedSubtotal == null) return const SizedBox.shrink();

    // Calculate actual items total
    final itemsTotal = state.draft.items.fold<Decimal>(
      Decimal.zero,
      (sum, item) => sum + item.itemTotal,
    );

    // Calculate difference
    final difference = (itemsTotal - expectedSubtotal).abs();
    final tolerance = Decimal.parse('0.01');
    final isMatch = difference <= tolerance;

    // Only show warning if there's a mismatch
    if (isMatch) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade700, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.receiptSplitReviewSubtotalWarningTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.receiptSplitReviewSubtotalWarningMessage(
                  '${currency.code} ${itemsTotal.toStringAsFixed(2)}',
                  '${currency.code} ${expectedSubtotal.toStringAsFixed(2)}',
                  '${currency.code} ${difference.toStringAsFixed(2)}',
                ),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildComparisonRow(
                      context.l10n.receiptSplitReviewExpectedSubtotal,
                      '${currency.code} ${expectedSubtotal.toStringAsFixed(2)}',
                      Colors.grey.shade700,
                    ),
                    const Divider(height: 16),
                    _buildComparisonRow(
                      context.l10n.receiptSplitReviewItemsTotal,
                      '${currency.code} ${itemsTotal.toStringAsFixed(2)}',
                      Colors.orange.shade900,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
