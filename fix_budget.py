import re

with open('lib/features/budgets/presentation/pages/create_custom_budget_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _addItem
new_add_item = '''  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddItemForm(
          onPickCategory: _showCategoryPickerModal,
          onSave: (name, amount, category) {
            setState(() {
              final input = _ChecklistItemInput();
              input.titleController.text = name;
              input.amountController.text = amount;
              input.selectedCategory = category;
              input.amountController.addListener(_onAmountChanged);
              _items.insert(0, input);
            });
            _onAmountChanged(); // update total
          },
        );
      },
    );
  }'''
content = re.sub(r'  void _addItem\(\) \{.*?\n  \}', new_add_item, content, flags=re.DOTALL)

# 2. Extract _showCategoryPickerModal
pick_category_match = re.search(r'  void _pickCategory\(int index\) async \{(.*?)\n    if \(result != null\) \{', content, re.DOTALL)
if pick_category_match:
    modal_body = pick_category_match.group(1)
    new_pick_category = f'''  Future<Map<String, dynamic>?> _showCategoryPickerModal() async {{{modal_body}
    return result;
  }}

  void _pickCategory(int index) async {{
    final result = await _showCategoryPickerModal();
    if (result != null) {{'''
    content = content.replace(pick_category_match.group(0), new_pick_category)
else:
    print("Could not find _pickCategory")

# 3. Add _buildLabel and replace _buildGlassInput in Checklist items
new_build_label = '''  Widget _buildLabel({
    required String text,
    required String hint,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26C6DA).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text.isEmpty ? hint : text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: text.isEmpty ? Colors.black38 : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildGlassInput'''
content = content.replace('  Widget _buildGlassInput', new_build_label)

checklist_fields = '''                    Expanded(
                      flex: 5,
                      child: _buildGlassInput(
                        controller: item.titleController,
                        hint: 'Item Name',
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildGlassInput(
                        controller: item.amountController,
                        hint: 'Amt',
                        theme: theme,
                        isNumber: true,
                      ),
                    ),'''

new_checklist_fields = '''                    Expanded(
                      flex: 5,
                      child: _buildLabel(
                        text: item.titleController.text,
                        hint: 'Item Name',
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildLabel(
                        text: item.amountController.text,
                        hint: 'Amt',
                        theme: theme,
                      ),
                    ),'''
content = content.replace(checklist_fields, new_checklist_fields)

# 4. Append _AddItemForm
add_item_form = '''
class _AddItemForm extends StatefulWidget {
  final Future<Map<String, dynamic>?> Function() onPickCategory;
  final Function(String name, String amount, Category? category) onSave;

  const _AddItemForm({Key? key, required this.onPickCategory, required this.onSave}) : super(key: key);

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  Category? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _pickCategory() async {
    final result = await widget.onPickCategory();
    if (result != null) {
      setState(() {
        _selectedCategory = result['category'] as Category?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 120,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Item',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              GestureDetector(
                onTap: _pickCategory,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF26C6DA).withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Builder(builder: (context) {
                      if (_selectedCategory == null) {
                        return const Icon(Icons.category_rounded,
                            size: 24, color: Color(0xFF26C6DA));
                      }
                      final iconStr = _selectedCategory!.icon;
                      final codePoint = int.tryParse(iconStr);
                      if (codePoint != null) {
                        return Icon(
                            IconData(codePoint,
                                fontFamily: 'MaterialIcons'),
                            size: 24,
                            color: const Color(0xFF26C6DA));
                      }
                      return Text(iconStr,
                          style: const TextStyle(fontSize: 24));
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(_nameController, 'Item Name'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(_amountController, 'Amount', isNumber: true),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E7EB),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty && _amountController.text.isNotEmpty) {
                    widget.onSave(_nameController.text, _amountController.text, _selectedCategory);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B2AC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
'''

content = content + add_item_form

with open('lib/features/budgets/presentation/pages/create_custom_budget_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
