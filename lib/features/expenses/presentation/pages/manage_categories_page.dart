import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import 'manage_subcategories_page.dart';
import '../widgets/set_budget_bottom_sheet.dart';
import '../widgets/category_icon.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final ValueNotifier<bool> _isAddingExpense = ValueNotifier(false);
  final ValueNotifier<bool> _isAddingIncome = ValueNotifier(false);
  final ValueNotifier<bool> _isSubpageActive = ValueNotifier(false);

  @override
  void dispose() {
    _isAddingExpense.dispose();
    _isAddingIncome.dispose();
    _isSubpageActive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Widget page = DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Categories',
              style: TextStyle(color: Color(0xFF1E293B))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF6D28D9), // Deep Purple
            labelColor: Color(0xFF6D28D9), // Deep Purple
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CategoryListView(isIncome: false, isAddingNotifier: _isAddingExpense, isSubpageActiveNotifier: _isSubpageActive),
            _CategoryListView(isIncome: true, isAddingNotifier: _isAddingIncome, isSubpageActiveNotifier: _isSubpageActive),
          ],
        ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton.extended(
            onPressed: () {
              final isIncome = DefaultTabController.of(context).index == 1;
              if (isIncome) {
                _isAddingIncome.value = true;
              } else {
                _isAddingExpense.value = true;
              }
            },
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          );
        }),
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: _isSubpageActive,
      builder: (context, isActive, child) {
        return AnimatedOpacity(
          opacity: isActive ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: child,
        );
      },
      child: page,
    );
  }
}

class _CategoryListView extends StatefulWidget {
  final bool isIncome;
  final ValueNotifier<bool> isAddingNotifier;
  final ValueNotifier<bool> isSubpageActiveNotifier;

  const _CategoryListView({
    required this.isIncome,
    required this.isAddingNotifier,
    required this.isSubpageActiveNotifier,
  });

  @override
  State<_CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<_CategoryListView> {
  String? _editingCategoryId;

  @override
  void initState() {
    super.initState();
    widget.isAddingNotifier.addListener(_onAddingChanged);
  }

  @override
  void dispose() {
    widget.isAddingNotifier.removeListener(_onAddingChanged);
    super.dispose();
  }

  void _onAddingChanged() {
    setState(() {
      if (widget.isAddingNotifier.value) {
        _editingCategoryId = null;
      }
    });
  }

  Future<void> _deleteCategory(BuildContext context, Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<CategoryCubit>().deleteCustomCategory(cat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const ShimmerTile();
        } else if (state is CategoryError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is CategoryLoaded) {
          final categories =
              state.categories.where((c) => c.isIncome == widget.isIncome).toList();

          final itemCount = categories.length + (widget.isAddingNotifier.value ? 1 : 0);

          if (itemCount == 0) {
            return const Center(child: Text('No categories found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final isAdding = widget.isAddingNotifier.value;
              if (isAdding && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _InlineCategoryForm(
                    isAdding: true,
                    isIncome: widget.isIncome,
                    onCancel: () {
                      widget.isAddingNotifier.value = false;
                    },
                    onSave: () {
                      widget.isAddingNotifier.value = false;
                    },
                  ),
                );
              }

              final catIndex = isAdding ? index - 1 : index;
              final cat = categories[catIndex];
              final isEditing = _editingCategoryId == cat.id;

              if (isEditing) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _InlineCategoryForm(
                    isAdding: false,
                    isIncome: widget.isIncome,
                    category: cat,
                    onCancel: () {
                      setState(() {
                        _editingCategoryId = null;
                      });
                    },
                    onSave: () {
                      setState(() {
                        _editingCategoryId = null;
                      });
                    },
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: CategoryIcon(
                      iconStr: cat.icon,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  title: Text(cat.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${cat.subcategories.length} subcategories'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!cat.isDefault)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              _editingCategoryId = cat.id;
                              widget.isAddingNotifier.value = false;
                            });
                          },
                        ),
                      if (!cat.isDefault)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.black),
                          onPressed: () => _deleteCategory(context, cat),
                        ),
                    ],
                  ),
                  onTap: () async {
                    widget.isSubpageActiveNotifier.value = true;
                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        transitionDuration: const Duration(milliseconds: 300),
                        reverseTransitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return ManageSubcategoriesPage(categoryId: cat.id);
                        },
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                    widget.isSubpageActiveNotifier.value = false;
                  },
                ),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _InlineCategoryForm extends StatefulWidget {
  final bool isAdding;
  final bool isIncome;
  final Category? category;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _InlineCategoryForm({
    required this.isAdding,
    required this.isIncome,
    this.category,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_InlineCategoryForm> createState() => _InlineCategoryFormState();
}

class _InlineCategoryFormState extends State<_InlineCategoryForm> {
  late TextEditingController _ctrl;
  late String _selectedIcon;
  late BucketType _selectedBucket;
  final Color _selectedColor = const Color(0xFF42A5F5); // Default since we don't display a color picker

  final List<String> _icons = [
    Icons.edit.codePoint.toString(), Icons.fastfood.codePoint.toString(), Icons.local_pizza.codePoint.toString(), Icons.local_cafe.codePoint.toString(), Icons.restaurant.codePoint.toString(), // Food
    Icons.directions_car.codePoint.toString(), Icons.flight.codePoint.toString(), Icons.train.codePoint.toString(), Icons.local_gas_station.codePoint.toString(), Icons.beach_access.codePoint.toString(), // Transport
    Icons.shopping_bag.codePoint.toString(), Icons.checkroom.codePoint.toString(), Icons.brush.codePoint.toString(), Icons.spa.codePoint.toString(), Icons.content_cut.codePoint.toString(), // Shopping
    Icons.movie.codePoint.toString(), Icons.sports_esports.codePoint.toString(), Icons.music_note.codePoint.toString(), Icons.local_play.codePoint.toString(), Icons.sports_soccer.codePoint.toString(), // Entertainment
    Icons.medical_services.codePoint.toString(), Icons.local_hospital.codePoint.toString(), Icons.fitness_center.codePoint.toString(), Icons.self_improvement.codePoint.toString(), Icons.sanitizer.codePoint.toString(), // Health
    Icons.lightbulb.codePoint.toString(), Icons.electric_bolt.codePoint.toString(), Icons.water_drop.codePoint.toString(), Icons.wifi.codePoint.toString(), Icons.build.codePoint.toString(), // Utilities
    Icons.school.codePoint.toString(), Icons.history_edu.codePoint.toString(), Icons.work.codePoint.toString(), Icons.computer.codePoint.toString(), Icons.smartphone.codePoint.toString(), // Education & Work
    Icons.attach_money.codePoint.toString(), Icons.account_balance.codePoint.toString(), Icons.home.codePoint.toString(), Icons.inventory_2.codePoint.toString(), Icons.shopping_cart.codePoint.toString(), // Finance
    Icons.pets.codePoint.toString(), Icons.child_care.codePoint.toString(), Icons.card_giftcard.codePoint.toString(), Icons.celebration.codePoint.toString(), Icons.favorite.codePoint.toString(), // Pets, Kids
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.category?.name ?? '');
    
    if (widget.isAdding) {
      _selectedIcon = _icons.first;
      _selectedBucket = BucketType.none;
    } else {
      _selectedIcon = widget.category?.icon ?? _icons.first;
      _selectedBucket = widget.category?.bucketType ?? BucketType.none;
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
      final category = Category(
        id: const Uuid().v4(),
        name: text,
        icon: _selectedIcon,
        color: _selectedColor,
        isDefault: false,
        isIncome: widget.isIncome,
        bucketType: _selectedBucket,
        subcategories: [],
        subcategoryBuckets: {},
        recurringConfigs: {},
      );
      context.read<CategoryCubit>().addCustomCategory(category);
    } else {
      final updated = widget.category!.copyWith(
        name: text,
        icon: _selectedIcon,
        bucketType: _selectedBucket,
      );
      context.read<CategoryCubit>().updateCategory(updated);
    }
    
    widget.onSave();
  }

  Widget _buildSegmentTab(BucketType type, String title, IconData icon) {
    final isSelected = _selectedBucket == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBucket = isSelected ? BucketType.none : type),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(4),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isAdding ? 'Add Category' : 'Edit Category', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category Name',
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
              const Text('Icon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final iconCode = _icons[index];
                    final isSelected = _selectedIcon == iconCode;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconCode),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: CategoryIcon(
                            iconStr: iconCode,
                            size: 24,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!widget.isIncome) ...[
                const SizedBox(height: 20),
                const Text('Default Bucket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      _buildSegmentTab(BucketType.dailyExpenses, 'Blow', Icons.work_outline),
                      _buildSegmentTab(BucketType.smile, 'Smile', Icons.flight_takeoff),
                      _buildSegmentTab(BucketType.fire, 'Fire', Icons.local_fire_department),
                      _buildSegmentTab(BucketType.mojo, 'Mojo', Icons.security),
                      _buildSegmentTab(BucketType.grow, 'Grow', Icons.eco),
                    ],
                  ),
                ),
              ],
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
