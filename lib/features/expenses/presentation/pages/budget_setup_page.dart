import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../domain/entities/category.dart';
import '../bloc/monthly_budget_cubit.dart';
import '../bloc/monthly_budget_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class BudgetSetupPage extends StatefulWidget {
  final int initialMonth;
  final int initialYear;

  const BudgetSetupPage({
    super.key,
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  State<BudgetSetupPage> createState() => _BudgetSetupPageState();
}

class _BudgetSetupPageState extends State<BudgetSetupPage> {
  late int _selectedMonth;
  late int _selectedYear;

  final TextEditingController _totalBudgetController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};

  MonthlyBudgetEntity? _currentBudget;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;

    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.userId : '';
    context.read<MonthlyBudgetCubit>().init(userId);
    context.read<MonthlyBudgetCubit>().loadBudget(_selectedMonth, _selectedYear);
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onMonthYearChanged(int month, int year) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
      _totalBudgetController.clear();
      for (final controller in _categoryControllers.values) {
        controller.clear();
      }
    });
    context.read<MonthlyBudgetCubit>().loadBudget(month, year);
  }

  void _populateForm(MonthlyBudgetEntity budget) {
    _currentBudget = budget;
    _totalBudgetController.text = budget.totalBudgetLimit > 0 ? budget.totalBudgetLimit.toStringAsFixed(0) : '';
    
    for (final entry in budget.categoryLimits.entries) {
      if (_categoryControllers.containsKey(entry.key)) {
        _categoryControllers[entry.key]!.text = entry.value > 0 ? entry.value.toStringAsFixed(0) : '';
      }
    }
  }

  Future<void> _saveBudget() async {
    final totalBudget = double.tryParse(_totalBudgetController.text.trim()) ?? 0.0;
    
    final Map<String, double> categoryLimits = {};
    for (final entry in _categoryControllers.entries) {
      final val = double.tryParse(entry.value.text.trim()) ?? 0.0;
      if (val > 0) {
        categoryLimits[entry.key] = val;
      }
    }

    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.userId : '';

    final budget = MonthlyBudgetEntity(
      id: _currentBudget?.id ?? '',
      userId: userId,
      month: _selectedMonth,
      year: _selectedYear,
      totalBudgetLimit: totalBudget,
      categoryLimits: categoryLimits,
    );

    await context.read<MonthlyBudgetCubit>().saveBudget(budget);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Setup Monthly Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveBudget,
          ),
        ],
      ),
      body: BlocConsumer<MonthlyBudgetCubit, MonthlyBudgetState>(
        listener: (context, state) {
          if (state is MonthlyBudgetLoaded && state.budget != null) {
            _populateForm(state.budget!);
          } else if (state is MonthlyBudgetLoaded && state.budget == null) {
             _currentBudget = null;
          } else if (state is MonthlyBudgetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Month/Year Selector
                _buildMonthSelector(theme),
                const SizedBox(height: 32),

                // 2. Total Budget Input
                Text('Total Budget', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildGlassInput(
                  controller: _totalBudgetController,
                  hint: 'e.g. 50000',
                  icon: Icons.account_balance_wallet_rounded,
                  theme: theme,
                ),
                const SizedBox(height: 32),

                // 3. Category Limits
                Text('Category Limits', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, categoryState) {
                    if (categoryState is CategoryLoaded) {
                      final expenseCategories = categoryState.categories.where((c) => !c.isIncome).toList();
                      
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: expenseCategories.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final category = expenseCategories[i];
                          if (!_categoryControllers.containsKey(category.id)) {
                            _categoryControllers[category.id] = TextEditingController();
                          }
                          return _buildCategoryInput(category, _categoryControllers[category.id]!, theme);
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: _saveBudget,
                    child: const Text('Save Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              int newMonth = _selectedMonth - 1;
              int newYear = _selectedYear;
              if (newMonth < 1) {
                newMonth = 12;
                newYear--;
              }
              _onMonthYearChanged(newMonth, newYear);
            },
          ),
          Text(
            '${months[_selectedMonth - 1]} $_selectedYear',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              int newMonth = _selectedMonth + 1;
              int newYear = _selectedYear;
              if (newMonth > 12) {
                newMonth = 1;
                newYear++;
              }
              _onMonthYearChanged(newMonth, newYear);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: theme.colorScheme.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryInput(Category category, TextEditingController controller, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: Text(category.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          Expanded(
            child: Text(category.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'Limit',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
