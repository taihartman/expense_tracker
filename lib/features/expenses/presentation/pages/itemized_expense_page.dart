import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../cubits/itemized_expense_cubit.dart';
import '../cubits/itemized_expense_state.dart';
import '../../domain/models/line_item.dart';
import '../../domain/models/item_assignment.dart';
import '../../domain/models/assignment_mode.dart';
import '../../domain/models/tax_extra.dart';
import '../../domain/models/tip_extra.dart';
import '../../domain/models/percent_base.dart';
import '../../../../core/models/currency_code.dart';

/// Minimal itemized expense creation page
class ItemizedExpensePage extends StatefulWidget {
  final String tripId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String payerUserId;
  final CurrencyCode currency;

  const ItemizedExpensePage({
    Key? key,
    required this.tripId,
    required this.participants,
    required this.participantNames,
    required this.payerUserId,
    required this.currency,
  }) : super(key: key);

  @override
  State<ItemizedExpensePage> createState() => _ItemizedExpensePageState();
}

class _ItemizedExpensePageState extends State<ItemizedExpensePage> {
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _taxController = TextEditingController();
  final _tipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize cubit with trip context
    context.read<ItemizedExpenseCubit>().init(
      tripId: widget.tripId,
      participants: widget.participants,
      payerUserId: widget.payerUserId,
      currency: widget.currency,
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _taxController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itemized Expense')),
      body: BlocConsumer<ItemizedExpenseCubit, ItemizedExpenseState>(
        listener: (context, state) {
          if (state is ItemizedExpenseSaved) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Expense saved!')));
            Navigator.of(context).pop();
          } else if (state is ItemizedExpenseError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is ItemizedExpenseInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ItemizedExpenseSaving) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving expense...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItemsSection(context, state),
                const SizedBox(height: 24),
                _buildExtrasSection(context, state),
                const SizedBox(height: 24),
                _buildBreakdownSection(context, state),
                const SizedBox(height: 24),
                _buildSaveButton(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, ItemizedExpenseState state) {
    final items = _getItems(state);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildItemCard(context, item)),
            const SizedBox(height: 16),
            _buildAddItemForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, LineItem item) {
    final assignedUsers = item.assignment.users;
    final assignmentText = assignedUsers.isEmpty
        ? 'Not assigned'
        : assignedUsers
              .map((id) => widget.participantNames[id] ?? id)
              .join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '${item.quantity} × ${item.unitPrice} = ${item.itemTotal}\n$assignmentText',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () => _showAssignDialog(context, item),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () =>
                  context.read<ItemizedExpenseCubit>().removeItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemForm(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _itemNameController,
            decoration: const InputDecoration(labelText: 'Item name'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _itemPriceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _addItem(context),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildExtrasSection(BuildContext context, ItemizedExpenseState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tax & Tip',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _taxController,
              decoration: const InputDecoration(
                labelText: 'Tax %',
                hintText: 'e.g. 8.875',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateTax(context, value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tipController,
              decoration: const InputDecoration(
                labelText: 'Tip %',
                hintText: 'e.g. 18',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateTip(context, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownSection(
    BuildContext context,
    ItemizedExpenseState state,
  ) {
    if (state is! ItemizedExpenseReady &&
        state is! ItemizedExpenseCalculating) {
      return const SizedBox.shrink();
    }

    if (state is ItemizedExpenseCalculating) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final readyState = state as ItemizedExpenseReady;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${readyState.grandTotal}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            const Text(
              'Per Person:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...readyState.participantBreakdown.entries.map((entry) {
              final name = widget.participantNames[entry.key] ?? entry.key;
              final breakdown = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name),
                    Text(
                      breakdown.total.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, ItemizedExpenseState state) {
    final canSave = state is ItemizedExpenseReady && state.canSave;
    final errors = _getValidationErrors(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errors.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (error) => Text(
                      '• $error',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  )
                  .toList(),
            ),
          ),
        ElevatedButton(
          onPressed: canSave
              ? () => context.read<ItemizedExpenseCubit>().save()
              : null,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: const Text('Save Expense', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  void _addItem(BuildContext context) {
    final name = _itemNameController.text.trim();
    final priceText = _itemPriceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) return;

    try {
      final price = Decimal.parse(priceText);
      final item = LineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        quantity: Decimal.one,
        unitPrice: price,
        taxable: true,
        serviceChargeable: false,
        assignment: ItemAssignment(mode: AssignmentMode.even, users: []),
      );

      context.read<ItemizedExpenseCubit>().addItem(item);

      _itemNameController.clear();
      _itemPriceController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid price: $e')));
    }
  }

  void _showAssignDialog(BuildContext context, LineItem item) {
    final selectedUsers = Set<String>.from(item.assignment.users);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Assign: ${item.name}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.participants.map((userId) {
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateTax(BuildContext context, String value) {
    if (value.isEmpty) {
      context.read<ItemizedExpenseCubit>().setTax(null);
      return;
    }

    try {
      final taxValue = Decimal.parse(value);
      final tax = TaxExtra.percent(
        value: taxValue,
        base: PercentBase.preTaxItemSubtotals,
      );
      context.read<ItemizedExpenseCubit>().setTax(tax);
    } catch (e) {
      // Invalid input, ignore
    }
  }

  void _updateTip(BuildContext context, String value) {
    if (value.isEmpty) {
      context.read<ItemizedExpenseCubit>().setTip(null);
      return;
    }

    try {
      final tipValue = Decimal.parse(value);
      final tip = TipExtra.percent(
        value: tipValue,
        base: PercentBase.preTaxItemSubtotals,
      );
      context.read<ItemizedExpenseCubit>().setTip(tip);
    } catch (e) {
      // Invalid input, ignore
    }
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

  List<String> _getValidationErrors(ItemizedExpenseState state) {
    if (state is ItemizedExpenseEditing) {
      return state.validationErrors;
    } else if (state is ItemizedExpenseReady) {
      return state.draft.validationErrors;
    }
    return [];
  }
}
