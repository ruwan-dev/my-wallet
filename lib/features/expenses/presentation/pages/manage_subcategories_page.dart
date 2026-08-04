import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/settings_cubit.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';

class ManageSubcategoriesPage extends StatelessWidget {
  final String categoryId;

  const ManageSubcategoriesPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          category.recurringConfigs.containsKey(sub) ? Icons.event_repeat : Icons.event_available,
                          color: category.recurringConfigs.containsKey(sub) ? Theme.of(context).colorScheme.primary : Colors.grey,
                        ),
                        onPressed: () => _showRecurringSetup(context, category, sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editSubcategory(context, category, sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteSubcategory(context, category, sub),
                      ),
                    ],
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
        BucketType selectedBucket = category.bucketType != BucketType.none ? category.bucketType : BucketType.dailyExpenses;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Subcategory'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(hintText: 'Subcategory Name'),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  const Text('Assign to Bucket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: BucketType.values.where((b) => b != BucketType.none).map((bucket) {
                        final isSelected = selectedBucket == bucket;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              bucket.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => selectedBucket = bucket);
                              }
                            },
                            selectedColor: const Color(0xFF6D28D9),
                            backgroundColor: Colors.grey.shade200,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
                      final updatedBuckets = Map<String, BucketType>.from(category.subcategoryBuckets);
                      updatedBuckets[text] = selectedBucket;

                      final updated = category.copyWith(
                        subcategories: [...category.subcategories, text],
                        subcategoryBuckets: updatedBuckets,
                      );
                      context.read<CategoryCubit>().updateCategory(updated);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _editSubcategory(BuildContext context, Category category, String oldName) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: oldName);
        BucketType selectedBucket = category.subcategoryBuckets[oldName] ?? BucketType.none;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Subcategory'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(hintText: 'Subcategory Name'),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  const Text('Assign to Bucket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: BucketType.values.where((b) => b != BucketType.none).map((bucket) {
                        final isSelected = selectedBucket == bucket;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              bucket.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => selectedBucket = bucket);
                              }
                            },
                            selectedColor: const Color(0xFF6D28D9), // Deep Purple
                            backgroundColor: Colors.grey.shade200,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6D28D9)),
                  onPressed: () {
                    final newName = ctrl.text.trim();
                    if (newName.isEmpty) return;

                    // Rename logic
                    final updatedSubcategories = List<String>.from(category.subcategories);
                    final index = updatedSubcategories.indexOf(oldName);
                    if (index != -1) {
                      updatedSubcategories[index] = newName;
                    }

                    // Update buckets map
                    final updatedBuckets = Map<String, BucketType>.from(category.subcategoryBuckets);
                    updatedBuckets.remove(oldName);
                    if (selectedBucket != BucketType.none) {
                      updatedBuckets[newName] = selectedBucket;
                    }

                    // Update recurring configs map
                    final updatedRecurringConfigs = Map<String, dynamic>.from(category.recurringConfigs);
                    if (updatedRecurringConfigs.containsKey(oldName)) {
                      updatedRecurringConfigs[newName] = updatedRecurringConfigs.remove(oldName);
                    }

                    final updated = category.copyWith(
                      subcategories: updatedSubcategories,
                      subcategoryBuckets: updatedBuckets,
                      recurringConfigs: updatedRecurringConfigs,
                    );
                    context.read<CategoryCubit>().updateCategory(updated);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
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
      final updatedConfigs = Map<String, dynamic>.from(category.recurringConfigs)..remove(sub);
      final updated = category.copyWith(subcategories: updatedList, recurringConfigs: updatedConfigs);
      context.read<CategoryCubit>().updateCategory(updated);
    }
  }

  void _showRecurringSetup(BuildContext context, Category category, String sub) {
    final existingConfig = category.recurringConfigs[sub] as Map?;
    String frequency = existingConfig?['frequency'] ?? 'Monthly';
    DateTime nextDueDate = existingConfig != null && existingConfig['dueDate'] != null
        ? DateTime.parse(existingConfig['dueDate'])
        : DateTime.now();
    final amountController = TextEditingController(text: existingConfig?['amount']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final theme = Theme.of(ctx);
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recurring Schedule', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Set up a recurring schedule for $sub.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),

                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                    items: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => frequency = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Expected Amount',
                      border: const OutlineInputBorder(),
                      prefixText: '${ctx.watch<SettingsCubit>().state.currencySymbol} ',
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Next Due Date'),
                    subtitle: Text('${nextDueDate.year}-${nextDueDate.month.toString().padLeft(2, '0')}-${nextDueDate.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: nextDueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => nextDueDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      if (existingConfig != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              final configs = Map<String, dynamic>.from(category.recurringConfigs)..remove(sub);
                              final updated = category.copyWith(recurringConfigs: configs);
                              context.read<CategoryCubit>().updateCategory(updated);
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Remove'),
                          ),
                        ),
                      if (existingConfig != null) const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final configs = Map<String, dynamic>.from(category.recurringConfigs);
                            configs[sub] = {
                              'frequency': frequency,
                              'dueDate': nextDueDate.toIso8601String(),
                              'amount': double.tryParse(amountController.text) ?? 0.0,
                            };
                            final updated = category.copyWith(recurringConfigs: configs);
                            context.read<CategoryCubit>().updateCategory(updated);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save Schedule'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
