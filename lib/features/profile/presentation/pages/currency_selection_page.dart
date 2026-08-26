import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/bloc/settings_cubit.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';
class CurrencySelectionPage extends StatefulWidget {
  const CurrencySelectionPage({super.key});

  @override
  State<CurrencySelectionPage> createState() => _CurrencySelectionPageState();
}

class _CurrencySelectionPageState extends State<CurrencySelectionPage> {
  static const List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'LKR', 'symbol': 'Rs ', 'name': 'Sri Lankan Rupee'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  ];

  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = context.read<SettingsCubit>().state.currencyCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Default Currency',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              if (_selectedCode != null) {
                final selected = _currencies.firstWhere((c) => c['code'] == _selectedCode);
                context.read<SettingsCubit>().updateCurrency(
                      selected['symbol']!,
                      selected['code']!,
                    );
              }
              context.pop();
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF38B2AC), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: _currencies.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final currency = _currencies[index];
            final isSelected = currency['code'] == _selectedCode;

            return GlassListTile(
              tileColor: Colors.white,
              onTap: () {
                setState(() {
                  _selectedCode = currency['code'];
                });
              },
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF38B2AC).withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currency['symbol']!.trim(),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF38B2AC) : const Color(0xFF64748B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                '${currency['code']} - ${currency['name']}',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF38B2AC))
                  : null,
            );
          },
        ),
      ),
    );
  }
}
