import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../shared/widgets/currency_search_field.dart';
import 'package:flutter/material.dart';

/// A widget that allows users to select and reorder multiple currencies for a trip.
///
/// Features:
/// - Display selected currencies as chips with up/down/remove buttons
/// - Add currencies via "Add Currency" button
/// - Reorder currencies (first = default currency for new expenses)
/// - Validation: 1-10 currencies, no duplicates
/// - Mobile-first design with responsive sizing
///
/// Usage:
/// ```dart
/// MultiCurrencySelector(
///   selectedCurrencies: [CurrencyCode.usd, CurrencyCode.eur],
///   onChanged: (currencies) {
///     // Handle currency update
///   },
/// )
/// ```
class MultiCurrencySelector extends StatefulWidget {
  const MultiCurrencySelector({
    super.key,
    required this.selectedCurrencies,
    required this.onChanged,
    this.maxCurrencies = 10,
    this.minCurrencies = 1,
  });

  /// Currently selected currencies (ordered, first = default)
  final List<CurrencyCode> selectedCurrencies;

  /// Called when user adds, removes, or reorders currencies
  /// Callback receives updated list of currencies
  final ValueChanged<List<CurrencyCode>> onChanged;

  /// Maximum number of currencies allowed (default: 10)
  final int maxCurrencies;

  /// Minimum number of currencies required (default: 1)
  final int minCurrencies;

  @override
  State<MultiCurrencySelector> createState() => _MultiCurrencySelectorState();
}

class _MultiCurrencySelectorState extends State<MultiCurrencySelector> {
  late List<CurrencyCode> _currencies;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the input list
    _currencies = List<CurrencyCode>.from(widget.selectedCurrencies);
  }

  @override
  void didUpdateWidget(MultiCurrencySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if input changes
    if (oldWidget.selectedCurrencies != widget.selectedCurrencies) {
      _currencies = List<CurrencyCode>.from(widget.selectedCurrencies);
    }
  }

  void _moveCurrencyUp(int index) {
    if (index <= 0) return; // Can't move first item up

    setState(() {
      final temp = _currencies[index];
      _currencies[index] = _currencies[index - 1];
      _currencies[index - 1] = temp;
    });

    widget.onChanged(_currencies);
  }

  void _moveCurrencyDown(int index) {
    if (index >= _currencies.length - 1) return; // Can't move last item down

    setState(() {
      final temp = _currencies[index];
      _currencies[index] = _currencies[index + 1];
      _currencies[index + 1] = temp;
    });

    widget.onChanged(_currencies);
  }

  void _removeCurrency(int index) {
    // Don't remove if it would violate minimum constraint
    if (_currencies.length <= widget.minCurrencies) {
      return;
    }

    setState(() {
      _currencies.removeAt(index);
    });

    widget.onChanged(_currencies);
  }

  Future<void> _addCurrency() async {
    // Check max currencies limit before opening modal
    if (_currencies.length >= widget.maxCurrencies) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.multiCurrencySelectorMaxError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Open currency picker modal
    final selectedCurrency = await CurrencySearchField.showCurrencyPicker(
      context,
      showOnlyActive: true,
    );

    // User cancelled selection
    if (selectedCurrency == null) return;

    // Check for duplicate
    if (_currencies.contains(selectedCurrency)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.multiCurrencySelectorDuplicateError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Valid addition - append to list and notify parent
    setState(() {
      _currencies.add(selectedCurrency);
    });

    widget.onChanged(_currencies);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final chipSpacing = isMobile ? 8.0 : 12.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final touchTargetSize = isMobile ? 44.0 : 48.0;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            context.l10n.multiCurrencySelectorTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: isMobile ? 8 : 12),

          // Help text
          Text(
            context.l10n.multiCurrencySelectorHelpText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Currency chips
          if (_currencies.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  context.l10n.multiCurrencySelectorMinError,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: chipSpacing,
              runSpacing: chipSpacing,
              children: List.generate(_currencies.length, (index) {
                final currency = _currencies[index];
                final isFirst = index == 0;
                final isLast = index == _currencies.length - 1;
                final canRemove = _currencies.length > widget.minCurrencies;

                return _CurrencyChipItem(
                  currency: currency,
                  isFirst: isFirst,
                  isLast: isLast,
                  canRemove: canRemove,
                  iconSize: iconSize,
                  touchTargetSize: touchTargetSize,
                  fontSize: isMobile ? 14.0 : 16.0,
                  onMoveUp: () => _moveCurrencyUp(index),
                  onMoveDown: () => _moveCurrencyDown(index),
                  onRemove: () => _removeCurrency(index),
                );
              }),
            ),

          SizedBox(height: isMobile ? 16 : 20),

          // Add Currency button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currencies.length >= widget.maxCurrencies
                  ? null
                  : _addCurrency,
              child: Text(context.l10n.multiCurrencySelectorAddButton),
            ),
          ),

          // Error message when max currencies reached
          if (_currencies.length >= widget.maxCurrencies)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.l10n.multiCurrencySelectorMaxError,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper widget to render a single currency chip with action buttons
/// Uses a custom Material container instead of Chip to support interactive buttons
class _CurrencyChipItem extends StatelessWidget {
  const _CurrencyChipItem({
    required this.currency,
    required this.isFirst,
    required this.isLast,
    required this.canRemove,
    required this.iconSize,
    required this.touchTargetSize,
    required this.fontSize,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final CurrencyCode currency;
  final bool isFirst;
  final bool isLast;
  final bool canRemove;
  final double iconSize;
  final double touchTargetSize;
  final double fontSize;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Currency code (creates a Chip visual)
            Chip(
              label: Text(
                currency.code.toUpperCase(),
                style: TextStyle(fontSize: fontSize),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),

            // Up arrow button (hidden for first chip)
            if (!isFirst)
              SizedBox(
                width: touchTargetSize,
                height: touchTargetSize,
                child: IconButton(
                  icon: Icon(Icons.arrow_upward, size: iconSize),
                  onPressed: onMoveUp,
                  tooltip: context.l10n.multiCurrencySelectorMoveUp,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

            // Down arrow button (hidden for last chip)
            if (!isLast)
              SizedBox(
                width: touchTargetSize,
                height: touchTargetSize,
                child: IconButton(
                  icon: Icon(Icons.arrow_downward, size: iconSize),
                  onPressed: onMoveDown,
                  tooltip: context.l10n.multiCurrencySelectorMoveDown,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

            // Remove button (disabled at min currencies)
            SizedBox(
              width: touchTargetSize,
              height: touchTargetSize,
              child: IconButton(
                icon: Icon(Icons.close, size: iconSize),
                onPressed: canRemove ? onRemove : null,
                tooltip: context.l10n.multiCurrencySelectorRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
