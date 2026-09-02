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
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialDebt?.name ?? '');
    _totalCtrl = TextEditingController(text: widget.initialDebt?.totalAmount.toString() ?? '');
    _balanceCtrl = TextEditingController(text: widget.initialDebt?.currentBalance.toString() ?? '');
    _selectedDueDate = widget.initialDebt?.dueDate;
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
    if (total > 0 && balance > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('"Need to be paid" cannot be greater than "Total Amount"')),
      );
      return;
    }

    if (widget.initialDebt != null) {
      context.read<DebtCubit>().editDebt(
            debtId: widget.initialDebt!.id,
            name: name,
            totalAmount: total > 0 ? total : balance,
            currentBalance: balance,
            dueDate: _selectedDueDate,
          );
    } else {
      context.read<DebtCubit>().addDebt(
            name: name,
            totalAmount: total > 0 ? total : balance,
            currentBalance: balance,
            dueDate: _selectedDueDate,
          );
    }

    widget.onSave();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00ACC1),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF60C5B8).withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.white70),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDueDate != null
                          ? "${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}"
                          : 'Due Date (Optional)',
                      style: TextStyle(
                        color: _selectedDueDate != null ? Colors.white : Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
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
                  onTap: _handleSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60C5B8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      cursorColor: Colors.cyanAccent,
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
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}
