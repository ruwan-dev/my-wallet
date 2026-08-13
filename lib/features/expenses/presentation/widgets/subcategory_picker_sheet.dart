import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class SubcategoryPickerSheet extends StatefulWidget {
  final Category category;

  const SubcategoryPickerSheet({super.key, required this.category});

  @override
  State<SubcategoryPickerSheet> createState() => _SubcategoryPickerSheetState();
}

class _SubcategoryPickerSheetState extends State<SubcategoryPickerSheet> {
  final _controller = TextEditingController();
  late Category _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSubcategory() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_currentCategory.subcategories.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory already exists.')),
      );
      return;
    }

    final updated = _currentCategory.copyWith(
      subcategories: [..._currentCategory.subcategories, text],
    );
    context.read<CategoryCubit>().updateCategory(updated);
    
    setState(() {
      _currentCategory = updated;
      _controller.clear();
    });
  }

  void _removeSubcategory(String sub) {
    final updatedList = List<String>.from(_currentCategory.subcategories)..remove(sub);
    final updated = _currentCategory.copyWith(subcategories: updatedList);
    context.read<CategoryCubit>().updateCategory(updated);
    
    setState(() {
      _currentCategory = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Subcategories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentCategory.subcategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No subcategories added yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _currentCategory.subcategories.length,
                itemBuilder: (context, index) {
                  final sub = _currentCategory.subcategories[index];
                  return GlassListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sub),
                    onTap: () => Navigator.pop(context, sub),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
                      onPressed: () => _removeSubcategory(sub),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'New subcategory...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addSubcategory(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _addSubcategory,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
