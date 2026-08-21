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
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class CreateCustomBudgetPage extends StatefulWidget {
  final CustomBudgetEntity? existingBudget;

  const CreateCustomBudgetPage({super.key, this.existingBudget});

  @override
  State<CreateCustomBudgetPage> createState() => _CreateCustomBudgetPageState();
}

class _CreateCustomBudgetPageState extends State<CreateCustomBudgetPage> {
  final _titleController = TextEditingController();

  final List<_ChecklistItemInput> _items = [];
  bool _isLoading = false;
  BucketType _selectedBucket = BucketType.dailyExpenses;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      final budget = widget.existingBudget!;
      _titleController.text = budget.title;
      _selectedBucket = budget.bucketType;

      for (var item in budget.items) {
        final input = _ChecklistItemInput();
        input.titleController.text = item.title;
        input.amountController.text =
            item.allocatedAmount > 0 ? item.allocatedAmount.toString() : '';
        if (item.categoryId != null) {
          input.selectedCategory = Category(
              id: item.categoryId!,
              name: '',
              icon: item.categoryIcon ?? '?',
              color: Colors.grey,
              subcategories: []);
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

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        Category? selectedCategory;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final bool showingSubcategories = selectedCategory != null && selectedCategory!.subcategories.isNotEmpty;

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (showingSubcategories) ...[
                                IconButton(
                                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                                  onPressed: () => setState(() => selectedCategory = null),
                                ),
                                Expanded(
                                  child: Text('Subcategories for ${selectedCategory!.name}', 
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.check, color: theme.colorScheme.onSurface),
                                  onPressed: () => Navigator.pop(ctx, {'category': selectedCategory, 'subcategory': null}),
                                ),
                              ] else ...[
                                Text('Select Category', 
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ]
                            ],
                          ),
                        ),
                        Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                        if (showingSubcategories) ...[
                          ListTile(
                            title: Text('None', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                            onTap: () => Navigator.pop(ctx, {'category': selectedCategory, 'subcategory': null}),
                          ),
                          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: selectedCategory!.subcategories.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                              itemBuilder: (context, i) {
                                final sub = selectedCategory!.subcategories[i];
                                return ListTile(
                                  title: Text(sub, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                                  onTap: () => Navigator.pop(ctx, {'category': selectedCategory, 'subcategory': sub}),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: categoryState.categories.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                              itemBuilder: (context, i) {
                                final cat = categoryState.categories[i];
                                return ListTile(
                                  leading: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child: Builder(builder: (context) {
                                        final codePoint = int.tryParse(cat.icon);
                                        if (codePoint != null) {
                                          return Icon(
                                              IconData(codePoint, fontFamily: 'MaterialIcons'),
                                              size: 20,
                                              color: Colors.black);
                                        }
                                        return Text(cat.icon, style: const TextStyle(fontSize: 20));
                                      }),
                                    ),
                                  ),
                                  title: Text(cat.name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                                  onTap: () {
                                    if (cat.subcategories.isEmpty) {
                                      Navigator.pop(ctx, {'category': cat, 'subcategory': null});
                                    } else {
                                      setState(() => selectedCategory = cat);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _items[index].selectedCategory = result['category'] as Category?;
        _items[index].selectedSubcategory = result['subcategory'] as String?;
      });
    }
  }

  Future<void> _saveBudget() async {
    final title = _titleController.text.trim();
    const limit = 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a budget title')),
      );
      return;
    }

    final budgetState = context.read<CustomBudgetCubit>().state;
    if (budgetState is CustomBudgetLoaded) {
      final isDuplicate = budgetState.budgets.any((b) =>
          b.title.toLowerCase() == title.toLowerCase() &&
          b.id != widget.existingBudget?.id);
      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A budget with this name already exists')),
        );
        return;
      }
    }

    final checklist = <BudgetChecklistItem>[];
    const uuid = Uuid();

    for (var input in _items) {
      final itemTitle = input.titleController.text.trim();
      final itemAmount =
          double.tryParse(input.amountController.text.trim()) ?? 0.0;

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
      bucketType: _selectedBucket,
    );

    await context.read<CustomBudgetCubit>().saveBudget(budget);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
            widget.existingBudget == null ? 'Create Budget' : 'Edit Budget',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                  child: SizedBox(
                      width: 20, height: 20, child: ShimmerTile())),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Color(0xFF26C6DA), size: 28),
              onPressed: _saveBudget,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSegmentedControl(context),
            const SizedBox(height: 24),
            Text('Details',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildGlassInput(
              controller: _titleController,
              hint: 'Budget Title (e.g. Vacation)',
              icon: Icons.title_rounded,
              theme: theme,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Checklist Items',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18, color: Color(0xFF26C6DA)),
                  label: const Text('Add Item',
                      style: TextStyle(
                          color: Color(0xFF26C6DA), fontWeight: FontWeight.bold)),
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
                        width: 48,
                        height: 48,
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
                            if (item.selectedCategory == null) {
                              return const Icon(Icons.category_rounded,
                                  size: 20, color: Color(0xFF26C6DA));
                            }
                            final iconStr = item.selectedCategory!.icon;
                            final codePoint = int.tryParse(iconStr);
                            if (codePoint != null) {
                              return Icon(
                                  IconData(codePoint,
                                      fontFamily: 'MaterialIcons'),
                                  size: 20,
                                  color: const Color(0xFF26C6DA));
                            }
                            return Text(iconStr,
                                style: const TextStyle(fontSize: 20));
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent),
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


  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    required ThemeData theme,
    bool isNumber = false,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF26C6DA),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black38),
          prefixIcon:
              icon != null ? Icon(icon, color: const Color(0xFF26C6DA), size: 20) : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF26C6DA), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF26C6DA).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildSegmentTab(BucketType.dailyExpenses, 'Blow', Icons.work_outline)),
          Expanded(child: _buildSegmentTab(BucketType.splurge, 'Splurge', Icons.card_giftcard)),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(BucketType type, String title, IconData icon) {
    final isSelected = _selectedBucket == type;
    return GestureDetector(
        onTap: () => setState(() => _selectedBucket = type),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF26C6DA) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 4),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
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
