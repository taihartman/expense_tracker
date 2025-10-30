import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/trip_cubit.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../domain/models/trip.dart';
import '../../../../core/l10n/l10n_extensions.dart';

/// Page for editing an existing trip
class TripEditPage extends StatefulWidget {
  final Trip trip;

  const TripEditPage({super.key, required this.trip});

  @override
  State<TripEditPage> createState() => _TripEditPageState();
}

class _TripEditPageState extends State<TripEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CurrencyCode _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.name);
    _selectedCurrency = widget.trip.baseCurrency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<TripCubit>().updateTripDetails(
        tripId: widget.trip.id,
        name: _nameController.text.trim(),
        baseCurrency: _selectedCurrency,
      );
      context.go(AppRoutes.tripSettings(widget.trip.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tripEditTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.tripBackToSettings,
          onPressed: () {
            context.go(AppRoutes.tripSettings(widget.trip.id));
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          children: [
            CustomTextField(
              controller: _nameController,
              label: context.l10n.tripFieldNameLabel,
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
            DropdownButtonFormField<CurrencyCode>(
              initialValue: _selectedCurrency,
              decoration: InputDecoration(
                labelText: context.l10n.tripFieldBaseCurrencyLabel,
                helperText: context.l10n.tripFieldBaseCurrencyEditHelper,
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
            const SizedBox(height: AppTheme.spacing1),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: AppTheme.spacing1),
                  Expanded(
                    child: Text(
                      context.l10n.tripCurrencyChangedInfo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing3),
            CustomButton(
              text: context.l10n.tripSaveChangesButton,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
