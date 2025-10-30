import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';
import '../../../cubits/itemized_expense_cubit.dart';
import '../../../cubits/itemized_expense_state.dart';
import '../../../../domain/models/extras.dart';
import '../../../../domain/models/tip_extra.dart';
import '../../../../domain/models/percent_base.dart';
import '../../../../../../core/l10n/l10n_extensions.dart';

/// Step 4: Configure tip (tax already collected in receipt info step)
class ExtrasStepPage extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ExtrasStepPage({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<ExtrasStepPage> createState() => _ExtrasStepPageState();
}

class _ExtrasStepPageState extends State<ExtrasStepPage> {
  final _tipController = TextEditingController();
  bool _hasTip = false;
  bool _initialized = false;

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  void _initializeFromState(ItemizedExpenseState state) {
    if (_initialized) return;

    final extras = _getExtras(state);
    if (extras == null) return;

    // Initialize tip
    if (extras.tip != null) {
      setState(() {
        _hasTip = true;
        if (extras.tip!.type == 'percent') {
          _tipController.text = extras.tip!.value.toString();
        }
      });
    }

    _initialized = true;
  }

  Extras? _getExtras(ItemizedExpenseState state) {
    if (state is ItemizedExpenseEditing) {
      return state.extras;
    } else if (state is ItemizedExpenseCalculating) {
      return state.draft.extras;
    } else if (state is ItemizedExpenseReady) {
      return state.draft.extras;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemizedExpenseCubit, ItemizedExpenseState>(
      builder: (context, state) {
        // Initialize from state if editing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeFromState(state);
        });

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.receiptSplitExtrasTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.receiptSplitExtrasDescription,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTipCard(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildNavigationButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  context.l10n.receiptSplitExtrasTipCardTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _hasTip,
                  onChanged: (value) {
                    setState(() {
                      _hasTip = value;
                      if (!value) {
                        _tipController.clear();
                        context.read<ItemizedExpenseCubit>().setTip(null);
                      }
                    });
                  },
                ),
              ],
            ),
            if (_hasTip) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _tipController,
                decoration: InputDecoration(
                  labelText: context.l10n.receiptSplitExtrasTipRateLabel,
                  hintText: context.l10n.receiptSplitExtrasTipRateHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.percent),
                  helperText: context.l10n.receiptSplitExtrasTipRateHelper,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _updateTip(value),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['15', '18', '20', '25']
                    .map(
                      (rate) => FilterChip(
                        label: Text('$rate%'),
                        onSelected: (selected) {
                          if (selected) {
                            _tipController.text = rate;
                            _updateTip(rate);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.receiptSplitExtrasInfoMessage,
                style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
            onPressed: widget.onContinue,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(context.l10n.receiptSplitExtrasContinueButton),
          ),
        ),
      ],
    );
  }

  void _updateTip(String value) {
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
}
