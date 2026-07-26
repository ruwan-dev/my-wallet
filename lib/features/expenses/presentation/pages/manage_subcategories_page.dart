import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';

class ManageSubcategoriesPage extends StatelessWidget {
  final String categoryId;

  const ManageSubcategoriesPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoaded) {
              final cat = state.categories.firstWhere((c) => c.id == categoryId, orElse: () => Category(id: '', name: 'Unknown', icon: '', color: Colors.grey, isIncome: false, subcategories: []));
              return Text('${cat.name} Subcategories');
            }
            return const Text('Subcategories');
          },
        ),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CategoryError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is CategoryLoaded) {
            final category = state.categories.firstWhere((c) => c.id == categoryId, orElse: () => Category(id: '', name: 'Unknown', icon: '', color: Colors.grey, isIncome: false, subcategories: []));
            
            if (category.id.isEmpty) {
              return const Center(child: Text('Category not found.'));
            }

            if (category.subcategories.isEmpty) {
              return const Center(child: Text('No subcategories yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: category.subcategories.length,
              itemBuilder: (context, index) {
                final sub = category.subcategories[index];
                return ListTile(
                  leading: const Icon(Icons.subdirectory_arrow_right),
                  title: Text(sub),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteSubcategory(context, category, sub),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoaded) {
            final category = state.categories.firstWhere((c) => c.id == categoryId, orElse: () => Category(id: '', name: 'Unknown', icon: '', color: Colors.grey, isIncome: false, subcategories: []));
            return FloatingActionButton.extended(
              onPressed: () => _addSubcategory(context, category),
              icon: const Icon(Icons.add),
              label: const Text('Add Subcategory'),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _addSubcategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Subcategory'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Subcategory Name'),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = ctrl.text.trim();
                if (text.isNotEmpty && !category.subcategories.contains(text)) {
                  final updated = category.copyWith(
                    subcategories: [...category.subcategories, text],
                  );
                  context.read<CategoryCubit>().updateCategory(updated);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSubcategory(BuildContext context, Category category, String sub) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subcategory?'),
        content: Text('Are you sure you want to delete "$sub"?'),
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
      final updatedList = List<String>.from(category.subcategories)..remove(sub);
      final updated = category.copyWith(subcategories: updatedList);
      context.read<CategoryCubit>().updateCategory(updated);
    }
  }
}
