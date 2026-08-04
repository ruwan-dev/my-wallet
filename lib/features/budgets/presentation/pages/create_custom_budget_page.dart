import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/custom_budget.dart';
import '../bloc/custom_budget_cubit.dart';
import '../bloc/custom_budget_state.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/presentation/bloc/category_cubit.dart';
import '../../../expenses/presentation/bloc/category_state.dart';

class CreateCustomBudgetPage extends StatefulWidget {
  final CustomBudgetEntity? existingBudget;

  const CreateCustomBudgetPage({super.key, this.existingBudget});

  @override
  State<CreateCustomBudgetPage> createState() => _CreateCustomBudgetPageState();
}

class _CreateCustomBudgetPageState extends State<CreateCustomBudgetPage> {
  final _titleController = TextEditingController();
  final _limitController = TextEditingController();
  
  final List<_ChecklistItemInput> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      final budget = widget.existingBudget!;
      _titleController.text = budget.title;
      _limitController.text = budget.totalBudgetLimit > 0 ? budget.totalBudgetLimit.toString() : '';
      
      for (var item in budget.items) {
        final input = _ChecklistItemInput();
        input.titleController.text = item.title;
        input.amountController.text = item.allocatedAmount > 0 ? item.allocatedAmount.toString() : '';
        if (item.categoryId != null) {
          input.selectedCategory = Category(
            id: item.categoryId!, 
            name: '', 
            icon: item.categoryIcon ?? '?', 
            color: Colors.grey, 
            subcategories: []
          );
        }
        input.selectedSubcategory = item.subcategory;
        input.amountController.addListener(_onAmountChanged);
        _items.add(input);
      }
      
      if (_items.isEmpty) {
        final input = _ChecklistItemInput();
        input.amountController.addListener(_onAmountChanged);
        _items.add(input);
      }
    } else {
      final input = _ChecklistItemInput();
      input.amountController.addListener(_onAmountChanged);
      _items.add(input);
    }
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _limitController.dispose();
    for (var item in _items) {
      item.amountController.removeListener(_onAmountChanged);
      item.titleController.dispose();
      item.amountController.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      final input = _ChecklistItemInput();
      input.amountController.addListener(_onAmountChanged);
      _items.insert(0, input); // Add to the top of the list
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _items.removeAt(index);
      item.amountController.removeListener(_onAmountChanged);
      item.titleController.dispose();
      item.amountController.dispose();
    });
  }

  void _pickCategory(int index) async {
    final categoryState = context.read<CategoryCubit>().state;
    if (categoryState is! CategoryLoaded) return;
    
    final selected = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: categoryState.categories.length,
            itemBuilder: (context, i) {
              final cat = categoryState.categories[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cat.color.withOpacity(0.2),
                  child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(cat.name),
                onTap: () => Navigator.pop(ctx, cat),
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      String? selectedSubcategory;
      if (selected.subcategories.isNotEmpty) {
        selectedSubcategory = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: selected.subcategories.length,
                itemBuilder: (context, i) {
                  final sub = selected.subcategories[i];
                  return ListTile(
                    title: Text(sub),
                    onTap: () => Navigator.pop(ctx, sub),
                  );
                },
              ),
            );
          },
        );
      }

      setState(() {
        _items[index].selectedCategory = selected;
        _items[index].selectedSubcategory = selectedSubcategory;
      });
    }
  }

  Future<void> _saveBudget() async {
    final title = _titleController.text.trim();
    final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a budget title')),
      );
      return;
    }

    final budgetState = context.read<CustomBudgetCubit>().state;
    if (budgetState is CustomBudgetLoaded) {
      final isDuplicate = budgetState.budgets.any((b) => 
        b.title.toLowerCase() == title.toLowerCase() && b.id != widget.existingBudget?.id
      );
      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A budget with this name already exists')),
        );
        return;
      }
    }

    final checklist = <BudgetChecklistItem>[];
    const uuid = Uuid();

    for (var input in _items) {
      final itemTitle = input.titleController.text.trim();
      final itemAmount = double.tryParse(input.amountController.text.trim()) ?? 0.0;
      
      if (itemTitle.isNotEmpty) {
        checklist.add(BudgetChecklistItem(
          id: uuid.v4(),
          title: itemTitle,
          allocatedAmount: itemAmount,
          categoryId: input.selectedCategory?.id,
          categoryIcon: input.selectedCategory?.icon,
          subcategory: input.selectedSubcategory,
        ));
      }
    }

    setState(() => _isLoading = true);

    final budget = CustomBudgetEntity(
      id: widget.existingBudget?.id ?? '',
      userId: widget.existingBudget?.userId ?? '', // set by Cubit if empty
      title: title,
      totalBudgetLimit: limit,
      items: checklist,
      createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      isCompleted: widget.existingBudget?.isCompleted ?? false,
    );

    await context.read<CustomBudgetCubit>().saveBudget(budget);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.existingBudget == null ? 'Create Budget' : 'Edit Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _saveBudget,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildGlassInput(
              controller: _titleController,
              hint: 'Budget Title (e.g. Vacation)',
              icon: Icons.title_rounded,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildGlassInput(
              controller: _limitController,
              hint: 'Total Limit (Optional)',
              icon: Icons.account_balance_wallet_rounded,
              theme: theme,
              isNumber: true,
            ),
            
            const SizedBox(height: 32),
            _buildAllocationChart(theme),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Checklist Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickCategory(index),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: item.selectedCategory?.color.withOpacity(0.2) ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(
                            item.selectedCategory?.icon ?? '?',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildGlassInput(
                        controller: item.titleController,
                        hint: 'Item',
                        icon: Icons.flight_rounded,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: _buildGlassInput(
                        controller: item.amountController,
                        hint: 'Amount',
                        icon: Icons.attach_money_rounded,
                        theme: theme,
                        isNumber: true,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationChart(ThemeData theme) {
    double totalAllocated = 0.0;
    final Map<String, double> categoryAmounts = {};
    final Map<String, Color> categoryColors = {};

    for (var item in _items) {
      final amount = double.tryParse(item.amountController.text.trim()) ?? 0.0;
      if (amount > 0) {
        totalAllocated += amount;
        final catName = item.selectedCategory?.name ?? 'Uncategorized';
        final catColor = item.selectedCategory?.color ?? Colors.grey;
        
        categoryAmounts[catName] = (categoryAmounts[catName] ?? 0.0) + amount;
        categoryColors[catName] = catColor;
      }
    }

    if (totalAllocated == 0) return const SizedBox.shrink();

    final sections = categoryAmounts.entries.map((entry) {
      return PieChartSectionData(
        color: categoryColors[entry.key],
        value: entry.value,
        title: '',
        radius: 24,
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 32,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Allocated', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatCurrency(context, totalAllocated),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: categoryAmounts.entries.map((e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: categoryColors[e.key])),
                      const SizedBox(width: 6),
                      Text(
                        e.key.isEmpty ? 'Uncategorized' : e.key, 
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)
                      ),
                    ],
                  )).toList(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItemInput {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  Category? selectedCategory;
  String? selectedSubcategory;
}
