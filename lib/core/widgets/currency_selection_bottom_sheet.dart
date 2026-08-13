import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_cubit.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class CurrencySelectionBottomSheet extends StatefulWidget {
  const CurrencySelectionBottomSheet({super.key});

  @override
  State<CurrencySelectionBottomSheet> createState() =>
      _CurrencySelectionBottomSheetState();
}

class _CurrencySelectionBottomSheetState
    extends State<CurrencySelectionBottomSheet> {
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
    // Initialize with current value
    _selectedCode = context.read<SettingsCubit>().state.currencyCode;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C).withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    const Text('Select Currency',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        if (_selectedCode != null) {
                          final selected = _currencies.firstWhere(
                              (c) => c['code'] == _selectedCode);
                          context.read<SettingsCubit>().updateCurrency(
                                selected['symbol']!,
                                selected['code']!,
                              );
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Save',
                          style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _currencies.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final currency = _currencies[index];
                    final isSelected = currency['code'] == _selectedCode;

                    return GlassListTile(
                      onTap: () {
                        setState(() {
                          _selectedCode = currency['code'];
                        });
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B5CF6).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            currency['symbol']!.trim(),
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        '${currency['code']} - ${currency['name']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF8B5CF6))
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
