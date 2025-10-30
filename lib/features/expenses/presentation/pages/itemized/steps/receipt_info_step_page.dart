import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../../../cubits/itemized_expense_cubit.dart';
import '../../../cubits/itemized_expense_state.dart';
import '../../../../../../core/l10n/l10n_extensions.dart';

/// Step 1: Enter receipt info (subtotal and tax)
class ReceiptInfoStepPage extends StatefulWidget {
  final String currencyCode;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const ReceiptInfoStepPage({
    super.key,
    required this.currencyCode,
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

  @override
  void initState() {
    super.initState();
    // Populate from existing state if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ItemizedExpenseCubit>().state;
      if (state is ItemizedExpenseEditing) {
        if (state.expectedSubtotal != null) {
          _subtotalController.text = state.expectedSubtotal.toString();
        }
        if (state.taxAmount != null) {
          _taxController.text = state.taxAmount.toString();
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
      final subtotal = Decimal.parse(_subtotalController.text.trim());
      final tax = _taxController.text.trim().isEmpty
          ? null
          : Decimal.parse(_taxController.text.trim());

      // Update cubit with receipt info
      context.read<ItemizedExpenseCubit>().setReceiptInfo(
        expectedSubtotal: subtotal,
        taxAmount: tax,
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
                const SizedBox(height: 32),

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
                        TextFormField(
                          controller: _subtotalController,
                          focusNode: _subtotalFocusNode,
                          decoration: InputDecoration(
                            labelText: context
                                .l10n
                                .receiptSplitReceiptInfoSubtotalLabel,
                            hintText: context
                                .l10n
                                .receiptSplitReceiptInfoSubtotalHint,
                            helperText: context
                                .l10n
                                .receiptSplitReceiptInfoSubtotalHelper,
                            helperMaxLines: 2,
                            prefixText: '${widget.currencyCode} ',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.l10n.validationRequired;
                            }
                            try {
                              final decimal = Decimal.parse(value.trim());
                              if (decimal <= Decimal.zero) {
                                return 'Subtotal must be greater than 0';
                              }
                            } catch (e) {
                              return context.l10n.validationInvalidNumber;
                            }
                            return null;
                          },
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
                        TextFormField(
                          controller: _taxController,
                          focusNode: _taxFocusNode,
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.receiptSplitReceiptInfoTaxLabel,
                            hintText:
                                context.l10n.receiptSplitReceiptInfoTaxHint,
                            helperText:
                                context.l10n.receiptSplitReceiptInfoTaxHelper,
                            prefixText: '${widget.currencyCode} ',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null; // Optional
                            }
                            try {
                              final decimal = Decimal.parse(value.trim());
                              if (decimal < Decimal.zero) {
                                return 'Tax cannot be negative';
                              }
                            } catch (e) {
                              return context.l10n.validationInvalidNumber;
                            }
                            return null;
                          },
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
