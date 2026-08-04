import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_budget.dart';
import '../bloc/budget_cubit.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';

class SetBudgetBottomSheet extends StatefulWidget {
  final Category? initialCategory;

  const SetBudgetBottomSheet({super.key, this.initialCategory});

  @override
  State<SetBudgetBottomSheet> createState() => _SetBudgetBottomSheetState();
}

class _SetBudgetBottomSheetState extends State<SetBudgetBottomSheet> {
  final _amountController = TextEditingController();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and valid amount')),
      );
      return;
    }

    final currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());

    final budget = CategoryBudgetEntity(
      id: '${_selectedCategory!.id}_$currentMonthYear',
      userId: '', // Cubit will inject correct userId via Repository
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      limitAmount: amount,
      monthYear: currentMonthYear,
    );

    context.read<BudgetCubit>().saveBudget(budget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 
        24, 
        24, 
        isKeyboardOpen ? MediaQuery.of(context).viewInsets.bottom + 24 : 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Set Monthly Budget', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_selectedCategory == null)
            BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoaded) {
                  final expenses = state.categories.where((c) => !c.isIncome).toList();
                  return DropdownButtonFormField<Category>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: expenses.map((c) => DropdownMenuItem(
                      value: c, 
                      child: Text('${c.icon} ${c.name}')
                    )).toList(),
                    onChanged: (cat) => setState(() => _selectedCategory = cat),
                  );
                }
                return const CircularProgressIndicator();
              }
            )
          else
            ListTile(
              leading: Text(_selectedCategory!.icon, style: const TextStyle(fontSize: 24)),
              title: Text(_selectedCategory!.name, style: theme.textTheme.titleMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedCategory = null),
              ),
              tileColor: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Budget Limit',
              prefixText: 'Rs ', // Should match user settings ideally
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }
}
