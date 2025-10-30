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
import '../widgets/add_item_modal.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemizedExpenseCubit, ItemizedExpenseState>(
      builder: (context, state) {
        final items = _getItems(state);
        final participants = _getParticipants(state);
        final currency = _getCurrency(state);
        final expectedSubtotal = _getExpectedSubtotal(state);
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final horizontalPadding = isMobile ? 12.0 : 16.0;

        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.receiptSplitItemsTitle,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    context.l10n.receiptSplitItemsDescription,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  if (expectedSubtotal != null)
                    _buildValidationBanner(
                      expectedSubtotal,
                      items,
                      currency,
                      isMobile,
                    ),
                  if (expectedSubtotal != null)
                    SizedBox(height: isMobile ? 12 : 16),
                  // Item count badge
                  if (items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState(isMobile)
                        : _buildItemsList(items, participants, isMobile),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildNavigationButtons(items.isNotEmpty, isMobile),
                ],
              ),
            ),
            // Floating Action Button
            Positioned(
              right: 16,
              bottom: 80,
              child: FloatingActionButton(
                onPressed: () => _showAddItemModal(context),
                tooltip: context.l10n.receiptSplitItemsAddButton,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: isMobile ? 56 : 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            context.l10n.receiptSplitItemsEmptyTitle,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.receiptSplitItemsEmptyDescription,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isMobile ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(
    List<LineItem> items,
    List<String> participants,
    bool isMobile,
  ) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, participants, isMobile);
      },
    );
  }

  Widget _buildItemCard(
    LineItem item,
    List<String> participants,
    bool isMobile,
  ) {
    final currency = _getCurrency(context.read<ItemizedExpenseCubit>().state);
    final isAssigned = item.assignment.users.isNotEmpty;
    final assignmentText = isAssigned
        ? item.assignment.users
              .map((id) => widget.participantNames[id] ?? id)
              .join(', ')
        : context.l10n.receiptSplitItemsNotAssigned;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${item.quantity} × ${currency.symbol}${item.unitPrice} = ${currency.symbol}${item.itemTotal}',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
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
                Expanded(
                  child: Text(
                    assignmentText,
                    style: TextStyle(
                      color: isAssigned ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              icon: Icon(Icons.people_alt, size: isMobile ? 20 : 24),
              tooltip: context.l10n.receiptSplitItemsAssignTooltip,
              onPressed: () => _showAssignDialog(item, participants),
              padding: isMobile ? const EdgeInsets.all(4) : null,
              constraints: isMobile
                  ? const BoxConstraints(minWidth: 36, minHeight: 36)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: isMobile ? 20 : 24),
              tooltip: context.l10n.receiptSplitItemsEditTooltip,
              onPressed: () => _showEditItemModal(context, item),
              padding: isMobile ? const EdgeInsets.all(4) : null,
              constraints: isMobile
                  ? const BoxConstraints(minWidth: 36, minHeight: 36)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: isMobile ? 20 : 24),
              tooltip: context.l10n.receiptSplitItemsRemoveTooltip,
              onPressed: () {
                context.read<ItemizedExpenseCubit>().removeItem(item.id);
              },
              padding: isMobile ? const EdgeInsets.all(4) : null,
              constraints: isMobile
                  ? const BoxConstraints(minWidth: 36, minHeight: 36)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemModal(BuildContext context) {
    final currency = _getCurrency(context.read<ItemizedExpenseCubit>().state);
    showAddItemModal(
      context: context,
      currencyCode: currency,
      onSave: (name, quantity, price) {
        _addItem(name, quantity, price);
      },
    );
  }

  void _showEditItemModal(BuildContext context, LineItem item) {
    final currency = _getCurrency(context.read<ItemizedExpenseCubit>().state);
    showAddItemModal(
      context: context,
      currencyCode: currency,
      editingItem: item,
      onSave: (name, quantity, price) {
        _updateItem(item.id, name, quantity, price);
      },
    );
  }

  Widget _buildNavigationButtons(bool hasItems, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
            ),
            child: Text(context.l10n.commonBack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: hasItems ? widget.onContinue : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
            ),
            child: Text(context.l10n.receiptSplitItemsContinueButton),
          ),
        ),
      ],
    );
  }

  void _addItem(String name, Decimal quantity, Decimal price) {
    final item = LineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      unitPrice: price,
      taxable: true,
      serviceChargeable: false,
      assignment: const ItemAssignment(mode: AssignmentMode.even, users: []),
    );

    context.read<ItemizedExpenseCubit>().addItem(item);

    // Scroll to bottom to show new item with animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateItem(
    String itemId,
    String name,
    Decimal quantity,
    Decimal price,
  ) {
    final cubit = context.read<ItemizedExpenseCubit>();
    final state = cubit.state;
    final items = _getItems(state);
    final existingItem = items.firstWhere((item) => item.id == itemId);

    final updatedItem = LineItem(
      id: existingItem.id,
      name: name,
      quantity: quantity,
      unitPrice: price,
      taxable: existingItem.taxable,
      serviceChargeable: existingItem.serviceChargeable,
      assignment: existingItem.assignment, // Preserve assignment
    );

    cubit.updateItem(itemId, updatedItem);
  }

  void _showAssignDialog(LineItem item, List<String> participants) {
    final selectedUsers = Set<String>.from(item.assignment.users);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.receiptSplitItemsAssignDialogTitle(item.name)),
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

  Decimal? _getExpectedSubtotal(ItemizedExpenseState state) {
    if (state is ItemizedExpenseEditing) {
      return state.expectedSubtotal;
    } else if (state is ItemizedExpenseCalculating) {
      return state.draft.expectedSubtotal;
    } else if (state is ItemizedExpenseReady) {
      return state.draft.expectedSubtotal;
    }
    return null;
  }

  Widget _buildValidationBanner(
    Decimal expectedSubtotal,
    List<LineItem> items,
    CurrencyCode currency,
    bool isMobile,
  ) {
    // Calculate current items total
    final currentTotal = items.fold<Decimal>(
      Decimal.zero,
      (sum, item) => sum + item.itemTotal,
    );

    // Calculate difference
    final difference = (currentTotal - expectedSubtotal).abs();
    final tolerance = Decimal.parse('0.01');
    final isMatch = difference <= tolerance;

    return Card(
      elevation: 2,
      color: isMatch ? Colors.green.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isMatch ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMatch ? Icons.check_circle : Icons.warning,
                  color: isMatch ? Colors.green : Colors.orange,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    isMatch
                        ? context.l10n.receiptSplitItemsSubtotalMatch
                        : context.l10n.receiptSplitItemsSubtotalMismatch,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                      color: isMatch
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 12),
            _buildValidationRow(
              context.l10n.receiptSplitItemsExpectedSubtotal,
              '${currency.code} ${expectedSubtotal.toStringAsFixed(2)}',
              Colors.grey.shade700,
              isMobile,
            ),
            SizedBox(height: isMobile ? 6 : 8),
            _buildValidationRow(
              context.l10n.receiptSplitItemsCurrentTotal,
              '${currency.code} ${currentTotal.toStringAsFixed(2)}',
              isMatch ? Colors.green.shade900 : Colors.orange.shade900,
              isMobile,
            ),
            SizedBox(height: isMobile ? 6 : 8),
            _buildValidationRow(
              context.l10n.receiptSplitItemsDifference,
              '${currency.code} ${difference.toStringAsFixed(2)}',
              isMatch ? Colors.green.shade900 : Colors.orange.shade900,
              isMobile,
            ),
            if (!isMatch) ...[
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                context.l10n.receiptSplitItemsValidationHelper,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationRow(
    String label,
    String value,
    Color color,
    bool isMobile,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
