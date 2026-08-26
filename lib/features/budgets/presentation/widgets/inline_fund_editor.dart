import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/formatters.dart';

class InlineFundEditor extends StatefulWidget {
  final String title;
  final Color themeColor;
  final List<Map<String, dynamic>> sourceAccounts;
  final VoidCallback onCancel;
  final Function(double, String) onSave;

  const InlineFundEditor({
    super.key,
    required this.title,
    required this.themeColor,
    required this.sourceAccounts,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<InlineFundEditor> createState() => _InlineFundEditorState();
}

class _InlineFundEditorState extends State<InlineFundEditor> {
  late final TextEditingController _amountCtrl;
  String? _selectedSourceId;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    if (widget.sourceAccounts.isNotEmpty) {
      _selectedSourceId = widget.sourceAccounts.first['id'];
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    final amountStr = _amountCtrl.text.trim();
    final amount = double.tryParse(amountStr) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedSourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source account')),
      );
      return;
    }

    final selectedSource = widget.sourceAccounts.firstWhere(
      (s) => s['id'] == _selectedSourceId,
      orElse: () => <String, dynamic>{},
    );

    if (selectedSource.isNotEmpty) {
      final double sourceBalance = selectedSource['balance'] as double? ?? 0.0;
      if (amount > sourceBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Insufficient funds (Balance: ${AppFormatters.formatCurrency(context, sourceBalance)})'),
          ),
        );
        return;
      }
    }

    widget.onSave(amount, _selectedSourceId!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
              widget.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSourceId,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'From Account / Vault',
                labelStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF00ACC1), width: 2),
                ),
              ),
              items: widget.sourceAccounts.map((source) {
                return DropdownMenuItem<String>(
                  value: source['id'],
                  child: Text(source['name'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSourceId = val;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              style: const TextStyle(color: Colors.black87),
              cursorColor: const Color(0xFF00ACC1),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF00ACC1), width: 2),
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
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _handleSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ACC1),
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
    );
  }
}
