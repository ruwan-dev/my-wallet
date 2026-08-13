import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bloc/settings_cubit.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class ManageSubcategoriesPage extends StatefulWidget {
  final String categoryId;

  const ManageSubcategoriesPage({super.key, required this.categoryId});

  @override
  State<ManageSubcategoriesPage> createState() => _ManageSubcategoriesPageState();
}

class _ManageSubcategoriesPageState extends State<ManageSubcategoriesPage> {
  String? _editingSubcategory;
  String? _schedulingSubcategory;
  bool _isAdding = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoaded) {
              final cat = state.categories.firstWhere((c) => c.id == widget.categoryId, orElse: () => Category(id: '', name: 'Unknown', icon: '', color: Colors.grey, isIncome: false, subcategories: []));
              return Text('${cat.name} Subcategories');
            }
            return const Text('Subcategories');
          },
        ),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const ShimmerTile();
          } else if (state is CategoryError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is CategoryLoaded) {
            final category = state.categories.firstWhere((c) => c.id == widget.categoryId, orElse: () => Category(id: '', name: 'Unknown', icon: '', color: Colors.grey, isIncome: false, subcategories: []));
            
            if (category.id.isEmpty) {
              return const Center(child: Text('Category not found.'));
            }

            final itemCount = category.subcategories.length + (_isAdding ? 1 : 0);

            if (itemCount == 0) {
              return const Center(child: Text('No subcategories yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == category.subcategories.length && _isAdding) {
                  // Add form
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _InlineSubcategoryForm(
                      category: category,
                      isAdding: true,
                      onCancel: () {
                        setState(() {
                          _isAdding = false;
                        });
                      },
                      onSave: () {
                        setState(() {
                          _isAdding = false;
                        });
                      },
                    ),
                  );
                }

                final sub = category.subcategories[index];
                final isEditing = _editingSubcategory == sub;
                final isScheduling = _schedulingSubcategory == sub;

                if (isEditing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _InlineSubcategoryForm(
                      category: category,
                      isAdding: false,
                      oldName: sub,
                      onCancel: () {
                        setState(() {
                          _editingSubcategory = null;
                        });
                      },
                      onSave: () {
                        setState(() {
                          _editingSubcategory = null;
                        });
                      },
                    ),
                  );
                }

                if (isScheduling) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _InlineRecurringSetupForm(
                      category: category,
                      subcategory: sub,
                      onCancel: () {
                        setState(() {
                          _schedulingSubcategory = null;
                        });
                      },
                      onSave: () {
                        setState(() {
                          _schedulingSubcategory = null;
                        });
                      },
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassListTile(
                    leading: const Icon(Icons.subdirectory_arrow_right),
                    title: Text(sub),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            category.recurringConfigs.containsKey(sub) ? Icons.event_repeat : Icons.event_available,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _schedulingSubcategory = sub;
                              _editingSubcategory = null;
                              _isAdding = false;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              _editingSubcategory = sub;
                              _schedulingSubcategory = null;
                              _isAdding = false;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.black),
                          onPressed: () => _deleteSubcategory(context, category, sub),
                        ),
                      ],
                    ),
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
            return FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isAdding = true;
                  _editingSubcategory = null;
                  _schedulingSubcategory = null;
                });
              },
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add),
              label: const Text('Add Subcategory'),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _InlineSubcategoryForm extends StatefulWidget {
  final Category category;
  final bool isAdding;
  final String? oldName;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _InlineSubcategoryForm({
    required this.category,
    required this.isAdding,
    this.oldName,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_InlineSubcategoryForm> createState() => _InlineSubcategoryFormState();
}

class _InlineSubcategoryFormState extends State<_InlineSubcategoryForm> {
  late TextEditingController _ctrl;
  late BucketType _selectedBucket;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.oldName ?? '');
    
    if (widget.isAdding) {
      _selectedBucket = widget.category.bucketType != BucketType.none 
          ? widget.category.bucketType 
          : BucketType.dailyExpenses;
    } else {
      _selectedBucket = widget.category.subcategoryBuckets[widget.oldName] ?? BucketType.none;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    if (widget.isAdding) {
      if (!widget.category.subcategories.contains(text)) {
        final updatedBuckets = Map<String, BucketType>.from(widget.category.subcategoryBuckets);
        updatedBuckets[text] = _selectedBucket;

        final updated = widget.category.copyWith(
          subcategories: [...widget.category.subcategories, text],
          subcategoryBuckets: updatedBuckets,
        );
        context.read<CategoryCubit>().updateCategory(updated);
      }
    } else {
      final oldName = widget.oldName!;
      final updatedSubcategories = List<String>.from(widget.category.subcategories);
      final index = updatedSubcategories.indexOf(oldName);
      if (index != -1) {
        updatedSubcategories[index] = text;
      }

      final updatedBuckets = Map<String, BucketType>.from(widget.category.subcategoryBuckets);
      updatedBuckets.remove(oldName);
      if (_selectedBucket != BucketType.none) {
        updatedBuckets[text] = _selectedBucket;
      }

      final updatedRecurringConfigs = Map<String, dynamic>.from(widget.category.recurringConfigs);
      if (updatedRecurringConfigs.containsKey(oldName)) {
        updatedRecurringConfigs[text] = updatedRecurringConfigs.remove(oldName);
      }

      final updated = widget.category.copyWith(
        subcategories: updatedSubcategories,
        subcategoryBuckets: updatedBuckets,
        recurringConfigs: updatedRecurringConfigs,
      );
      context.read<CategoryCubit>().updateCategory(updated);
    }
    
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isAdding ? 'Add Subcategory' : 'Edit Subcategory', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subcategory Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6D28D9)),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Text('Assign to Bucket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: BucketType.values.where((b) => b != BucketType.none).map((bucket) {
                    final isSelected = _selectedBucket == bucket;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedBucket = bucket),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            bucket.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: widget.onCancel,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: _handleSave,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6D28D9).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineRecurringSetupForm extends StatefulWidget {
  final Category category;
  final String subcategory;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _InlineRecurringSetupForm({
    required this.category,
    required this.subcategory,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_InlineRecurringSetupForm> createState() => _InlineRecurringSetupFormState();
}

class _InlineRecurringSetupFormState extends State<_InlineRecurringSetupForm> {
  late String _frequency;
  bool _hasExisting = false;

  @override
  void initState() {
    super.initState();
    final existingConfig = widget.category.recurringConfigs[widget.subcategory] as Map?;
    _frequency = existingConfig?['frequency'] ?? 'Monthly';
    _hasExisting = existingConfig != null;
  }

  void _handleSave() {
    final configs = Map<String, dynamic>.from(widget.category.recurringConfigs);
    configs[widget.subcategory] = {
      'frequency': _frequency,
      'dueDate': DateTime.now().toIso8601String(),
      'amount': 0.0,
    };
    final updated = widget.category.copyWith(recurringConfigs: configs);
    context.read<CategoryCubit>().updateCategory(updated);
    widget.onSave();
  }

  void _handleRemove() {
    final configs = Map<String, dynamic>.from(widget.category.recurringConfigs)..remove(widget.subcategory);
    final updated = widget.category.copyWith(recurringConfigs: configs);
    context.read<CategoryCubit>().updateCategory(updated);
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recurring Schedule', 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  if (_hasExisting)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: _handleRemove,
                      tooltip: 'Remove Schedule',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Set up a recurring schedule for ${widget.subcategory}.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _frequency,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2E2A4F),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                    items: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((String val) {
                      return DropdownMenuItem(
                        value: val, 
                        child: Text(val, style: const TextStyle(color: Colors.white))
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _frequency = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: widget.onCancel,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: _handleSave,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6D28D9).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
