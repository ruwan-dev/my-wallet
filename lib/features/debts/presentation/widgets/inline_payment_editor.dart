import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/debt_cubit.dart';
import '../../domain/entities/debt.dart';

class InlinePaymentEditor extends StatefulWidget {
  final Debt debt;
  final double currentFireBalance;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const InlinePaymentEditor({
    super.key,
    required this.debt,
    required this.currentFireBalance,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<InlinePaymentEditor> createState() => _InlinePaymentEditorState();
}

class _InlinePaymentEditorState extends State<InlinePaymentEditor> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.debt.currentBalance.toString());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _handlePay() {
    final amountStr = _amountCtrl.text.trim();
    final amount = double.tryParse(amountStr) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > widget.currentFireBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Fire Wallet balance')),
      );
      return;
    }

    context.read<DebtCubit>().payOffDebt(widget.debt.id, amount, 'default');
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.15),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay ${widget.debt.name}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Current Balance: Rs ${widget.debt.currentBalance.toStringAsFixed(2)}\nFire Wallet: Rs ${widget.currentFireBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFF7C3AED),
                decoration: InputDecoration(
                  labelText: 'Amount to Pay',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _handlePay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
