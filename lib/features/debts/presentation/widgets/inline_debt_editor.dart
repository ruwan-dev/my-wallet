import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/debt_cubit.dart';
import '../../domain/entities/debt.dart';

class InlineDebtEditor extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Debt? initialDebt;

  const InlineDebtEditor({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.initialDebt,
  });

  @override
  State<InlineDebtEditor> createState() => _InlineDebtEditorState();
}

class _InlineDebtEditorState extends State<InlineDebtEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _balanceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialDebt?.name ?? '');
    _totalCtrl = TextEditingController(text: widget.initialDebt?.totalAmount.toString() ?? '');
    _balanceCtrl = TextEditingController(text: widget.initialDebt?.currentBalance.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameCtrl.text.trim();
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final balanceStr = _balanceCtrl.text.trim();
    final balance = balanceStr.isEmpty ? total : (double.tryParse(balanceStr) ?? 0);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a debt name')),
      );
      return;
    }
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid balance or total amount')),
      );
      return;
    }

    if (widget.initialDebt != null) {
      context.read<DebtCubit>().editDebt(
            debtId: widget.initialDebt!.id,
            name: name,
            totalAmount: total > 0 ? total : balance,
            currentBalance: balance,
          );
    } else {
      context.read<DebtCubit>().addDebt(
            name: name,
            totalAmount: total > 0 ? total : balance,
            currentBalance: balance,
          );
    }

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
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialDebt != null ? 'Edit ${widget.initialDebt!.name}' : 'Add New Debt',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Debt Name',
                _nameCtrl,
                TextInputType.text,
                TextCapitalization.words,
                maxLength: 12,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Total Amount',
                _totalCtrl,
                const TextInputType.numberWithOptions(decimal: true),
                TextCapitalization.none,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Need to be paid',
                _balanceCtrl,
                const TextInputType.numberWithOptions(decimal: true),
                TextCapitalization.none,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _handleSave,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6D28D9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 24),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType type,
    TextCapitalization capitalization, {
    int? maxLength,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textCapitalization: capitalization,
      maxLength: maxLength,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      inputFormatters: formatters,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF7C3AED),
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: const BorderSide(color: Color(0xFF6D28D9)),
        ),
      ),
    );
  }
}
