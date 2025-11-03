import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../cubits/trip_cubit.dart';
import 'multi_currency_selector.dart';

/// Allowed Currencies Card
///
/// Displays allowed currencies for the trip as chips.
/// Tapping opens a modal bottom sheet to edit currencies.
class AllowedCurrenciesCard extends StatelessWidget {
  final String tripId;
  final List<CurrencyCode> allowedCurrencies;

  const AllowedCurrenciesCard({
    super.key,
    required this.tripId,
    required this.allowedCurrencies,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showCurrencySelector(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.currency_exchange,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: Text(
                      context.l10n.tripSettingsAllowedCurrenciesDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allowedCurrencies.map<Widget>((currency) {
                  final isDefault = currency == allowedCurrencies.first;
                  return Chip(
                    label: Text(
                      currency.code.toUpperCase() +
                          (isDefault
                              ? context
                                  .l10n.tripSettingsAllowedCurrenciesDefaultSuffix
                              : ''),
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: isDefault
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3)
                        : null,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        // Store the currency list in local state so we can track changes
        List<CurrencyCode> updatedCurrencies = List.from(allowedCurrencies);
        bool isSaving = false;

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: MultiCurrencySelector(
                            selectedCurrencies: updatedCurrencies,
                            onChanged: (currencies) {
                              // Update local state with the new currency list
                              setState(() {
                                updatedCurrencies = currencies;
                              });
                            },
                          ),
                        ),
                      ),
                      // Save button
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacing2),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    // Set loading state
                                    setState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      // Get current user for activity logging
                                      final currentUser = context
                                          .read<TripCubit>()
                                          .getCurrentUserForTrip(tripId);
                                      final actorName = currentUser?.name;

                                      await context
                                          .read<TripCubit>()
                                          .updateTripCurrencies(
                                            tripId: tripId,
                                            currencies: updatedCurrencies,
                                            actorName: actorName,
                                          );

                                      if (sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop();
                                        ScaffoldMessenger.of(sheetContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.l10n
                                                  .tripSettingsAllowedCurrenciesUpdateSuccess,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (sheetContext.mounted) {
                                        ScaffoldMessenger.of(sheetContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.l10n
                                                  .tripSettingsAllowedCurrenciesUpdateError(
                                                e.toString(),
                                              ),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Theme.of(
                                              sheetContext,
                                            ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setState(() {
                                          isSaving = false;
                                        });
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    context.l10n
                                        .tripSettingsAllowedCurrenciesSaveButton,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
