import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/trip_cubit.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Page for creating a new trip
class TripCreatePage extends StatefulWidget {
  const TripCreatePage({super.key});

  @override
  State<TripCreatePage> createState() => _TripCreatePageState();
}

class _TripCreatePageState extends State<TripCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CurrencyCode _selectedCurrency = CurrencyCode.usd;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<TripCubit>().createTrip(
            name: _nameController.text.trim(),
            baseCurrency: _selectedCurrency,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Trip Name',
              // e.g., Vietnam 2025
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a trip name';
                }
                if (value.trim().length > 100) {
                  return 'Trip name must be 100 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing2),
            DropdownButtonFormField<CurrencyCode>(
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Base Currency',
                helperText: 'All settlements will be calculated in this currency',
              ),
              items: CurrencyCode.values.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text('${currency.name.toUpperCase()} - ${_getCurrencyName(currency)}'),
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
              text: 'Create Trip',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencyName(CurrencyCode currency) {
    switch (currency) {
      case CurrencyCode.usd:
        return 'US Dollar';
      case CurrencyCode.vnd:
        return 'Vietnamese Dong';
    }
  }
}
