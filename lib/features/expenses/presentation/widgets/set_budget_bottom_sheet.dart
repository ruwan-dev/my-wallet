import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_budget.dart';
import '../bloc/budget_cubit.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class SetBudgetBottomSheet extends StatefulWidget {
  final Category? initialCategory;

  const SetBudgetBottomSheet({super.key, this.initialCategory});

  @override
  State<SetBudgetBottomSheet> createState() => _SetBudgetBottomSheetState();
}

class _SetBudgetBottomSheetState extends State<SetBudgetBottomSheet> {
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  void _save() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());

    final budget = CategoryBudgetEntity(
      id: '${_selectedCategory!.id}_$currentMonthYear',
      userId: '', // Cubit will inject correct userId via Repository
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      limitAmount: 0.0,
      monthYear: currentMonthYear,
    );

    context.read<BudgetCubit>().saveBudget(budget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
              Text('Set Monthly Budget', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
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
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Category>(
                        hint: const Text('Select Category', style: TextStyle(color: Colors.white70)),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2E2A4F),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                        items: expenses.map((c) {
                          final codePoint = int.tryParse(c.icon);
                          return DropdownMenuItem(
                            value: c, 
                            child: Row(
                              children: [
                                if (codePoint != null)
                                  Icon(IconData(codePoint, fontFamily: 'MaterialIcons'), size: 20, color: Colors.white)
                                else
                                  Text(c.icon, style: const TextStyle(color: Colors.white)),
                                const SizedBox(width: 12),
                                Text(c.name, style: const TextStyle(color: Colors.white)),
                              ],
                            )
                          );
                        }).toList(),
                        onChanged: (cat) => setState(() => _selectedCategory = cat),
                      ),
                    ),
                  );
                }
                return const ShimmerTile();
              }
            )
          else
            GlassListTile(
              leading: Builder(builder: (context) {
                final codePoint = int.tryParse(_selectedCategory!.icon);
                if (codePoint != null) {
                  return Icon(IconData(codePoint, fontFamily: 'MaterialIcons'), size: 24, color: Colors.white);
                }
                return Text(_selectedCategory!.icon, style: const TextStyle(fontSize: 24, color: Colors.white));
              }),
              title: Text(_selectedCategory!.name, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _selectedCategory = null),
              ),
              tileColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _save,
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Text(
                    'Save Budget',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )));
  }
}
