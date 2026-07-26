import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../widgets/add_category_bottom_sheet.dart';
import 'manage_subcategories_page.dart';
import '../widgets/set_budget_bottom_sheet.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryListView(isIncome: false),
            _CategoryListView(isIncome: true),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () {
                final isIncome = DefaultTabController.of(context).index == 1;
                _addCategory(context, isIncome);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            );
          }
        ),
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, bool isIncome) async {
    await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCategoryBottomSheet(isIncome: isIncome),
    );
  }
}

class _CategoryListView extends StatelessWidget {
  final bool isIncome;

  const _CategoryListView({required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CategoryError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is CategoryLoaded) {
          final categories = state.categories.where((c) => c.isIncome == isIncome).toList();

          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cat.color.withOpacity(0.2),
                  child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${cat.subcategories.length} subcategories'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!cat.isIncome)
                      IconButton(
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SetBudgetBottomSheet(initialCategory: cat),
                          );
                        },
                      ),
                    if (!cat.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteCategory(context, cat),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageSubcategoriesPage(categoryId: cat.id),
                    ),
                  );
                },
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Future<void> _deleteCategory(BuildContext context, Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<CategoryCubit>().deleteCustomCategory(cat.id);
    }
  }
}
