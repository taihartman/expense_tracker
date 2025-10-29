import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
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
      context.read<TripCubit>().createTrip(
        name: _tripNameController.text.trim(),
        baseCurrency: _selectedCurrency,
        creatorName: _creatorNameController.text.trim(),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tripCreateTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          children: [
            CustomTextField(
              controller: _tripNameController,
              label: context.l10n.tripFieldNameLabel,
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
            DropdownButtonFormField<CurrencyCode>(
              initialValue: _selectedCurrency,
              decoration: InputDecoration(
                labelText: context.l10n.tripFieldBaseCurrencyLabel,
                helperText: context.l10n.tripFieldBaseCurrencyHelper,
              ),
              items: CurrencyCode.values.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(
                    '${currency.name.toUpperCase()} - ${currency.displayName(context)}',
                  ),
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
            const SizedBox(height: AppTheme.spacing3),
            CustomButton(
              text: context.l10n.tripCreateButton,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
