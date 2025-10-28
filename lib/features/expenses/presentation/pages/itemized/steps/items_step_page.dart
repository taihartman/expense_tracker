import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../../../cubits/itemized_expense_cubit.dart';
import '../../../cubits/itemized_expense_state.dart';
import '../../../../domain/models/line_item.dart';
import '../../../../domain/models/item_assignment.dart';
import '../../../../domain/models/assignment_mode.dart';
import '../../../../../../core/models/currency_code.dart';
import '../../../../../../core/l10n/l10n_extensions.dart';

/// Step 2: Add line items and assign to people
class ItemsStepPage extends StatefulWidget {
  final Map<String, String> participantNames;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ItemsStepPage({
    super.key,
    required this.participantNames,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<ItemsStepPage> createState() => _ItemsStepPageState();
}

class _ItemsStepPageState extends State<ItemsStepPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String? _editingItemId; // Track which item is being edited

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemizedExpenseCubit, ItemizedExpenseState>(
      builder: (context, state) {
        final items = _getItems(state);
        final participants = _getParticipants(state);
        _getCurrency(state);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.itemizedItemsTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.itemizedItemsDescription,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : _buildItemsList(items, participants),
              ),
              const SizedBox(height: 16),
              _buildAddItemCard(),
              const SizedBox(height: 16),
              _buildNavigationButtons(items.isNotEmpty),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.itemizedItemsEmptyTitle,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.itemizedItemsEmptyDescription,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<LineItem> items, List<String> participants) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, participants);
      },
    );
  }

  Widget _buildItemCard(LineItem item, List<String> participants) {
    final currency = _getCurrency(context.read<ItemizedExpenseCubit>().state);
    final isAssigned = item.assignment.users.isNotEmpty;
    final assignmentText = isAssigned
        ? item.assignment.users
              .map((id) => widget.participantNames[id] ?? id)
              .join(', ')
        : context.l10n.itemizedItemsNotAssigned;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${item.quantity} × ${currency.symbol}${item.unitPrice} = ${currency.symbol}${item.itemTotal}',
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isAssigned ? Icons.people : Icons.person_off_outlined,
                  size: 16,
                  color: isAssigned ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  assignmentText,
                  style: TextStyle(
                    color: isAssigned ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people_alt),
              tooltip: context.l10n.itemizedItemsAssignTooltip,
              onPressed: () => _showAssignDialog(item, participants),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.itemizedItemsEditTooltip,
              onPressed: () => _startEditItem(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.itemizedItemsRemoveTooltip,
              onPressed: () {
                context.read<ItemizedExpenseCubit>().removeItem(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemCard() {
    final isEditMode = _editingItemId != null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isEditMode
                      ? context.l10n.itemizedItemsEditCardTitle
                      : context.l10n.itemizedItemsAddCardTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isEditMode) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _cancelEdit,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(context.l10n.commonCancel),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.itemizedItemsFieldNameLabel,
                hintText: context.l10n.itemizedItemsFieldNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.shopping_basket),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: context.l10n.itemizedItemsFieldQtyLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: context.l10n.itemizedItemsFieldPriceLabel,
                      hintText: context.l10n.itemizedItemsFieldPriceHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveItem,
                icon: Icon(isEditMode ? Icons.check : Icons.add),
                label: Text(
                  isEditMode
                      ? context.l10n.itemizedItemsUpdateButton
                      : context.l10n.itemizedItemsAddButton,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: isEditMode ? Colors.orange : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool hasItems) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(context.l10n.commonBack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: hasItems ? widget.onContinue : null,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(context.l10n.itemizedItemsContinueButton),
          ),
        ),
      ],
    );
  }

  void _saveItem() {
    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty || quantityText.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.validationPleaseFillAllFields)),
      );
      return;
    }

    try {
      final quantity = Decimal.parse(quantityText);
      final price = Decimal.parse(priceText);

      if (_editingItemId != null) {
        // Update existing item
        final cubit = context.read<ItemizedExpenseCubit>();
        final state = cubit.state;
        final items = _getItems(state);
        final existingItem = items.firstWhere(
          (item) => item.id == _editingItemId,
        );

        final updatedItem = LineItem(
          id: existingItem.id,
          name: name,
          quantity: quantity,
          unitPrice: price,
          taxable: existingItem.taxable,
          serviceChargeable: existingItem.serviceChargeable,
          assignment: existingItem.assignment, // Preserve assignment
        );

        cubit.updateItem(_editingItemId!, updatedItem);
      } else {
        // Add new item
        final item = LineItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          quantity: quantity,
          unitPrice: price,
          taxable: true,
          serviceChargeable: false,
          assignment: const ItemAssignment(
            mode: AssignmentMode.even,
            users: [],
          ),
        );

        context.read<ItemizedExpenseCubit>().addItem(item);
      }

      // Clear form
      _nameController.clear();
      _priceController.clear();
      _quantityController.text = '1';
      setState(() {
        _editingItemId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.validationInvalidInput(e.toString())),
        ),
      );
    }
  }

  void _startEditItem(LineItem item) {
    setState(() {
      _editingItemId = item.id;
      _nameController.text = item.name;
      _quantityController.text = item.quantity.toString();
      _priceController.text = item.unitPrice.toString();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingItemId = null;
      _nameController.clear();
      _priceController.clear();
      _quantityController.text = '1';
    });
  }

  void _showAssignDialog(LineItem item, List<String> participants) {
    final selectedUsers = Set<String>.from(item.assignment.users);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.itemizedItemsAssignDialogTitle(item.name)),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: participants.map((userId) {
                final name = widget.participantNames[userId] ?? userId;
                final isSelected = selectedUsers.contains(userId);

                return CheckboxListTile(
                  title: Text(name),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedUsers.add(userId);
                      } else {
                        selectedUsers.remove(userId);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newAssignment = ItemAssignment(
                mode: AssignmentMode.even,
                users: selectedUsers.toList(),
              );
              context.read<ItemizedExpenseCubit>().assignItem(
                item.id,
                newAssignment,
              );
              Navigator.of(dialogContext).pop();
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  List<LineItem> _getItems(ItemizedExpenseState state) {
    if (state is ItemizedExpenseEditing) {
      return state.items;
    } else if (state is ItemizedExpenseCalculating) {
      return state.draft.items;
    } else if (state is ItemizedExpenseReady) {
      return state.draft.items;
    }
    return [];
  }

  List<String> _getParticipants(ItemizedExpenseState state) {
    if (state is ItemizedExpenseEditing) {
      return state.participants;
    } else if (state is ItemizedExpenseCalculating) {
      return state.draft.participants;
    } else if (state is ItemizedExpenseReady) {
      return state.draft.participants;
    }
    return [];
  }

  CurrencyCode _getCurrency(ItemizedExpenseState state) {
    String currencyCode = 'USD';
    if (state is ItemizedExpenseEditing) {
      currencyCode = state.currencyCode;
    } else if (state is ItemizedExpenseCalculating) {
      currencyCode = state.draft.currencyCode;
    } else if (state is ItemizedExpenseReady) {
      currencyCode = state.draft.currencyCode;
    }
    return CurrencyCode.fromString(currencyCode) ?? CurrencyCode.usd;
  }
}
