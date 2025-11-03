import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../widgets/recovery_code_dialog.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/currency_search_field.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Page for creating a new trip
class TripCreatePage extends StatefulWidget {
  const TripCreatePage({super.key});

  @override
  State<TripCreatePage> createState() => _TripCreatePageState();
}

class _TripCreatePageState extends State<TripCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _creatorNameController = TextEditingController();
  CurrencyCode _selectedCurrency = CurrencyCode.usd;

  @override
  void dispose() {
    _tripNameController.dispose();
    _creatorNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Don't navigate immediately - let BlocListener handle it after showing recovery code
      context.read<TripCubit>().createTrip(
        name: _tripNameController.text.trim(),
        allowedCurrencies: [_selectedCurrency],
        creatorName: _creatorNameController.text.trim(),
      );
    }
  }

  /// Show recovery code dialog after trip creation
  Future<void> _showRecoveryCodeAfterCreation(
    String tripId,
    String tripName,
  ) async {
    try {
      // Query the recovery code from Firestore
      final recoveryCode = await context.read<TripCubit>().getRecoveryCode(
        tripId,
      );

      if (!mounted || recoveryCode == null) {
        // If code not found or widget unmounted, still navigate
        if (mounted) context.go(AppRoutes.home);
        return;
      }

      // Show recovery code dialog (non-dismissible via barrier)
      await showDialog(
        context: context,
        barrierDismissible: false, // Force user to acknowledge the code
        builder: (dialogContext) => RecoveryCodeDialog(
          code: recoveryCode.code,
          tripId: tripId,
          tripName: tripName,
          isFirstTime: true, // This is the first time they're seeing it
        ),
      );

      if (!mounted) return;

      // Reload trips to update the list, then navigate to home
      await context.read<TripCubit>().loadTrips();
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      // If recovery code fetch fails, still navigate (non-fatal)
      debugPrint('Failed to fetch recovery code after creation: $e');
      if (mounted) {
        // Reload trips to update the list, then navigate to home
        await context.read<TripCubit>().loadTrips();
        if (!mounted) return;
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tripCreateTitle)),
      body: BlocConsumer<TripCubit, TripState>(
        listener: (context, state) {
          if (state is TripCreated) {
            // Show recovery code, then navigate
            _showRecoveryCodeAfterCreation(state.trip.id, state.trip.name);
          } else if (state is TripError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isCreating = state is TripCreating;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              children: [
                CustomTextField(
                  controller: _tripNameController,
                  label: context.l10n.tripFieldNameLabel,
                  enabled: !isCreating,
                  // e.g., Vietnam 2025
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.validationPleaseEnterTripName;
                    }
                    if (value.trim().length > 100) {
                      return context.l10n.validationTripNameTooLong;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing2),
                CustomTextField(
                  controller: _creatorNameController,
                  label: context.l10n.tripFieldCreatorNameLabel,
                  hint: context.l10n.tripFieldCreatorNameHelper,
                  enabled: !isCreating,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.validationNameRequired;
                    }
                    if (value.trim().length > 50) {
                      return context.l10n.validationNameTooLong;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing2),
                CurrencySearchField(
                  value: _selectedCurrency,
                  label: context.l10n.tripFieldBaseCurrencyLabel,
                  enabled: !isCreating,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    helperText: context.l10n.tripFieldBaseCurrencyHelper,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing3),
                CustomButton(
                  text: context.l10n.tripCreateButton,
                  onPressed: isCreating ? null : _submit,
                ),
                // Loading state indicator
                if (isCreating) ...[
                  const SizedBox(height: AppTheme.spacing3),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing3),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppTheme.spacing2),
                        Text(
                          context.l10n.commonLoading,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
