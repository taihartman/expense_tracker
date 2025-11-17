import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../../../cubits/itemized_expense_cubit.dart';
import '../../../cubits/itemized_expense_state.dart';
import '../../../../../../core/l10n/l10n_extensions.dart';
import '../../../../../../core/models/currency_code.dart';
import '../../../../../../shared/widgets/currency_text_field.dart';
import '../../../../../../shared/utils/currency_input_formatter.dart';

/// Step 1: Enter receipt info (subtotal and tax)
class ReceiptInfoStepPage extends StatefulWidget {
  final CurrencyCode currencyCode;
  final List<CurrencyCode> allowedCurrencies; // T024: Trip's allowed currencies
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const ReceiptInfoStepPage({
    super.key,
    required this.currencyCode,
    required this.allowedCurrencies,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  State<ReceiptInfoStepPage> createState() => _ReceiptInfoStepPageState();
}

class _ReceiptInfoStepPageState extends State<ReceiptInfoStepPage> {
  final _formKey = GlobalKey<FormState>();
  final _subtotalController = TextEditingController();
  final _taxController = TextEditingController();
  final _subtotalFocusNode = FocusNode();
  final _taxFocusNode = FocusNode();
  late CurrencyCode _selectedCurrency; // T024: Track selected currency

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currencyCode; // T024: Initialize with default
    // Populate from existing state if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ItemizedExpenseCubit>().state;
      if (state is ItemizedExpenseEditing) {
        if (state.expectedSubtotal != null) {
          _subtotalController.text = formatAmountForInput(
            state.expectedSubtotal!,
            _selectedCurrency,
          );
        }
        if (state.taxAmount != null) {
          _taxController.text = formatAmountForInput(
            state.taxAmount!,
            _selectedCurrency,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _subtotalController.dispose();
    _taxController.dispose();
    _subtotalFocusNode.dispose();
    _taxFocusNode.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      final subtotalText = _subtotalController.text.trim();
      final subtotal = subtotalText.isEmpty
          ? Decimal.zero
          : Decimal.parse(stripCurrencyFormatting(subtotalText));

      final taxText = _taxController.text.trim();
      final tax = taxText.isEmpty
          ? null
          : Decimal.parse(stripCurrencyFormatting(taxText));

      // T024: Update cubit with receipt info and selected currency
      context.read<ItemizedExpenseCubit>().setReceiptInfo(
        expectedSubtotal: subtotal,
        taxAmount: tax,
        currencyCode: _selectedCurrency.code,
      );

      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemizedExpenseCubit, ItemizedExpenseState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.receiptSplitReceiptInfoTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.receiptSplitReceiptInfoDescription,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // T024: Currency dropdown (filtered to allowed currencies)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<CurrencyCode>(
                      initialValue: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: context.l10n.expenseFieldCurrencyLabel,
                        prefixIcon: const Icon(Icons.monetization_on),
                        border: const OutlineInputBorder(),
                      ),
                      items: widget.allowedCurrencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text('${currency.code} (${currency.symbol})'),
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
                  ),
                ),
                const SizedBox(height: 16),

                // Subtotal field (required)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CurrencyTextField(
                          controller: _subtotalController,
                          currencyCode: _selectedCurrency,
                          label:
                              context.l10n.receiptSplitReceiptInfoSubtotalLabel,
                          hint:
                              context.l10n.receiptSplitReceiptInfoSubtotalHint,
                          isRequired: false,
                          allowZero: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.receiptSplitReceiptInfoSubtotalHelper,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tax field (optional)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CurrencyTextField(
                          controller: _taxController,
                          currencyCode: _selectedCurrency,
                          label: context.l10n.receiptSplitReceiptInfoTaxLabel,
                          hint: context.l10n.receiptSplitReceiptInfoTaxHint,
                          isRequired: false,
                          allowZero: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.receiptSplitReceiptInfoTaxHelper,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
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
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          context.l10n.receiptSplitReceiptInfoContinueButton,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
