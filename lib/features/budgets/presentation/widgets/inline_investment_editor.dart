import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InlineInvestmentEditor extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const InlineInvestmentEditor({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<InlineInvestmentEditor> createState() => _InlineInvestmentEditorState();
}

class _InlineInvestmentEditorState extends State<InlineInvestmentEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _valueCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _valueCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameCtrl.text.trim();
    final value = double.tryParse(_valueCtrl.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an investment name')),
      );
      return;
    }
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid investment value')),
      );
      return;
    }

    // Mocking the save since the bloc isn't wired up for investments in the UI yet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Investment added successfully!')),
    );

    widget.onSave();
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
              'Add New Investment',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Investment Name',
              _nameCtrl,
              TextInputType.text,
              TextCapitalization.words,
              maxLength: 15,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Current Value',
              _valueCtrl,
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
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
        ),
      ),
    );
  }
}
