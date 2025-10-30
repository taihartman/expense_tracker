import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../../../../../core/l10n/l10n_extensions.dart';
import '../../../../../../core/models/currency_code.dart';
import '../../../../../../shared/utils/currency_input_formatter.dart';
import '../../../../../../shared/widgets/currency_text_field.dart';
import '../../../../domain/models/line_item.dart';

/// Modal bottom sheet for adding or editing a line item
class AddItemModal extends StatefulWidget {
  final LineItem? editingItem;
  final CurrencyCode currencyCode;
  final Function(String name, Decimal quantity, Decimal price) onSave;

  const AddItemModal({
    super.key,
    this.editingItem,
    required this.currencyCode,
    required this.onSave,
  });

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final editingItem = widget.editingItem;
    _nameController = TextEditingController(text: editingItem?.name ?? '');
    _priceController = TextEditingController(
      text: editingItem != null
          ? formatAmountForInput(editingItem.unitPrice, widget.currencyCode)
          : '',
    );
    _quantityController = TextEditingController(
      text: editingItem?.quantity.toString() ?? '1',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.editingItem != null;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + keyboardPadding,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Row(
                children: [
                  Icon(
                    isEditMode ? Icons.edit : Icons.add_shopping_cart,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditMode
                        ? context.l10n.receiptSplitItemsEditCardTitle
                        : context.l10n.receiptSplitItemsAddCardTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isEditMode)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: context.l10n.commonCancel,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Item Name Field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.receiptSplitItemsFieldNameLabel,
                  hintText: context.l10n.receiptSplitItemsFieldNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.shopping_basket),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.validationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Quantity and Price Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: context.l10n.receiptSplitItemsFieldQtyLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.validationRequired;
                        }
                        try {
                          final qty = Decimal.parse(value);
                          if (qty <= Decimal.zero) {
                            return context.l10n.validationMustBeGreaterThanZero;
                          }
                        } catch (e) {
                          return context.l10n.validationInvalidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CurrencyTextField(
                      controller: _priceController,
                      currencyCode: widget.currencyCode,
                      label: context.l10n.receiptSplitItemsFieldPriceLabel,
                      hint: context.l10n.receiptSplitItemsFieldPriceHint,
                      prefixIcon: Icons.attach_money,
                      allowZero: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveItem,
                  icon: Icon(isEditMode ? Icons.check : Icons.add),
                  label: Text(
                    isEditMode
                        ? context.l10n.receiptSplitItemsUpdateButton
                        : context.l10n.receiptSplitItemsAddButton,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: isEditMode ? Colors.orange : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();
    final priceText = stripCurrencyFormatting(_priceController.text.trim());

    try {
      final quantity = Decimal.parse(quantityText);
      final price = Decimal.parse(priceText);

      widget.onSave(name, quantity, price);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.validationInvalidInput(e.toString())),
        ),
      );
    }
  }
}

/// Shows the add/edit item modal bottom sheet
Future<void> showAddItemModal({
  required BuildContext context,
  required CurrencyCode currencyCode,
  LineItem? editingItem,
  required Function(String name, Decimal quantity, Decimal price) onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddItemModal(
      currencyCode: currencyCode,
      editingItem: editingItem,
      onSave: onSave,
    ),
  );
}
