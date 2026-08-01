import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/account_cubit.dart';
import '../bloc/account_state.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../widgets/add_category_bottom_sheet.dart';
import '../widgets/subcategory_picker_sheet.dart';
import '../widgets/recurring_timeline_widget.dart';

// ─── Step metadata ────────────────────────────────────────────────────────────

const int _kTotalSteps = 5;
const List<String> _kStepTitles = [
  'Transaction Type',
  'Category',
  'Account',
  'Title & Date',
  'How much?',
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class AddTransactionPage extends StatefulWidget {
  final TransactionEntity? existingTransaction;

  const AddTransactionPage({super.key, this.existingTransaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // ── Form state ───────────────────────────────────────────────────────────
  bool _isIncome = false;
  Category _selectedCategory = DefaultCategories.all.first;
  bool _categoryExplicitlySet = false;
  AccountEntity? _selectedAccount;
  AccountEntity? _transferTargetAccount;
  final _titleController = TextEditingController();
  final _subCategoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _recurrenceFrequency;
  final _amountController = TextEditingController();
  bool _isSaving = false;
  bool _isFixedExpense = false;

  // ── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final e = widget.existingTransaction;
    if (e != null) {
      _isIncome = e.isIncome;
      _selectedCategory = DefaultCategories.all.firstWhere(
        (c) => c.id == e.categoryId,
        orElse: () {
          if (e.categoryId.startsWith('liability_')) {
            return Category(
              id: e.categoryId,
              name: e.categoryName,
              icon: '💳',
              color: Colors.orange,
              isIncome: false,
            );
          }
          return DefaultCategories.all.first;
        },
      );
      _categoryExplicitlySet = true;
      _selectedDate = e.date;
      _recurrenceFrequency = e.recurrenceFrequency;
      _subCategoryController.text = e.subCategory ?? '';
      _titleController.text = e.title;
      final raw = e.amount.toStringAsFixed(2);
      _amountController.text =
          raw.endsWith('.00') ? raw.substring(0, raw.length - 3) : raw;
      _isFixedExpense = e.isFixedExpense;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accState = context.read<AccountCubit>().state;
    if (accState is AccountLoaded && _selectedAccount == null) {
      final e = widget.existingTransaction;
      if (e != null) {
        _selectedAccount = accState.accounts.firstWhere(
          (a) => a.id == e.accountId,
          orElse: () => accState.accounts.first,
        );
        if (e.transferAccountId != null) {
          _transferTargetAccount = accState.accounts.firstWhere(
            (a) => a.id == e.transferAccountId,
            orElse: () => accState.accounts.first,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _subCategoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _advance() {
    if (_currentStep >= _kTotalSteps - 1) return;
    int nextStep = _currentStep + 1;
    if (_isFixedExpense && nextStep == 2) {
      nextStep = 3; // Skip Account step
    }
    setState(() => _currentStep = nextStep);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  void _back() {
    if (_currentStep > 0) {
      int prevStep = _currentStep - 1;
      if (_isFixedExpense && prevStep == 2) {
        prevStep = 1; // Skip Account step backwards
      }
      setState(() => _currentStep = prevStep);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.pop();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final rawTitle = _titleController.text.trim();
    final title = rawTitle.isEmpty ? _selectedCategory.name : rawTitle;

    if (amount <= 0) {
      _snack('Enter a valid amount greater than zero');
      return;
    }
    if (!_isFixedExpense && _selectedAccount == null) {
      _snack('Please select an account first');
      return;
    }

    if (widget.existingTransaction != null && widget.existingTransaction!.nextDueDate != null) {
      final oldNextDueDate = widget.existingTransaction!.nextDueDate!;
      if (_selectedDate.isBefore(oldNextDueDate)) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              icon: Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 32),
              title: const Text('Early Entry?'),
              content: Text(
                'You are logging this transaction ahead of its scheduled date (${AppFormatters.formatDate(oldNextDueDate)}).\n\nIs this an early payment for the upcoming schedule?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Yes, Continue'),
                ),
              ],
            );
          },
        );
        if (proceed != true) {
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    DateTime? nextDueDate;
    final freq = _recurrenceFrequency;
    if (freq != null && freq != 'None') {
      switch (freq) {
        case 'Daily':
          nextDueDate = _selectedDate.add(const Duration(days: 1));
          break;
        case 'Weekly':
          nextDueDate = _selectedDate.add(const Duration(days: 7));
          break;
        case 'Monthly':
          nextDueDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
          break;
        case 'Yearly':
          nextDueDate = DateTime(_selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
          break;
      }
    }

    final tx = TransactionEntity(
      id:           widget.existingTransaction?.id ?? '',
      accountId:    _isFixedExpense ? 'planned' : _selectedAccount!.id,
      userId:       '',
      title:        title,
      amount:       amount,
      categoryId:   _selectedCategory.id,
      categoryName: _selectedCategory.name,
      subCategory:  _subCategoryController.text.trim().isEmpty ? null : _subCategoryController.text.trim(),
      date:         _selectedDate,
      isIncome:     _isIncome,
      note:         null,
      createdAt:    widget.existingTransaction?.createdAt ?? DateTime.now(),
      updatedAt:    DateTime.now(),
      recurrenceFrequency: freq == 'None' ? null : freq,
      nextDueDate:  nextDueDate,
      transferAccountId: _transferTargetAccount?.id,
      isFixedExpense: _isFixedExpense,
    );

    if (widget.existingTransaction == null) {
      await context.read<TransactionCubit>().addTransaction(tx);
    } else {
      await context.read<TransactionCubit>().updateTransaction(
            widget.existingTransaction!, tx);
    }

    if (mounted) context.pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleFavoriteTapped(TransactionEntity favorite) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return _FavoriteAccountPickerSheet(
          favorite: favorite,
          onSave: (amount, account) async {
            Navigator.pop(bottomSheetCtx);
            final newTx = TransactionEntity(
              id: '',
              accountId: account.id,
              userId: '',
              title: favorite.title,
              amount: amount,
              categoryId: favorite.categoryId,
              categoryName: favorite.categoryName,
              subCategory: favorite.subCategory,
              date: DateTime.now(),
              isIncome: favorite.isIncome,
              note: favorite.note,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              recurrenceFrequency: favorite.recurrenceFrequency,
              nextDueDate: null,
              isFavorite: false,
              transferAccountId: favorite.transferAccountId,
            );
            // ignore: invalid_use_of_visible_for_testing_member
            context.read<TransactionCubit>().addTransaction(newTx);
            if (mounted) context.pop();
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_rounded,
          ),
          onPressed: _back,
          tooltip: _currentStep == 0 ? 'Cancel' : 'Back',
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            _kStepTitles[_currentStep],
            key: ValueKey(_currentStep),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentStep + 1} of $_kTotalSteps',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
        children: [
          // ── Step progress bar ─────────────────────────────────────────────
          _StepProgressBar(step: _currentStep, total: _kTotalSteps),

          // ── Step content ──────────────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 1 — Type
                _Step1Type(
                  onSelected: (isIncome, isFixedExpense) {
                    setState(() {
                      _isIncome = isIncome;
                      _isFixedExpense = isFixedExpense;
                      final typeCategories = DefaultCategories.all.where((c) => c.isIncome == isIncome).toList();
                      if (typeCategories.isNotEmpty && !typeCategories.any((c) => c.id == _selectedCategory.id)) {
                        _selectedCategory = typeCategories.first;
                        _categoryExplicitlySet = false;
                      }
                    });
                    _advance();
                  },
                  onFavoriteTapped: _handleFavoriteTapped,
                ),

                // Step 2 — Category
                _Step2Category(
                   selectedCategory:      _selectedCategory,
                   categoryExplicitlySet: _categoryExplicitlySet,
                   isIncome:              _isIncome,
                   subCategoryController: _subCategoryController,
                   selectedAccountId:     _selectedAccount?.id,
                   onNext: _advance,
                   onCategoryTap: (cat) {
                    setState(() {
                      _selectedCategory       = cat;
                      _categoryExplicitlySet  = true;
                      
                      if (cat.id.startsWith('liability_')) {
                        final liabilityId = cat.id.replaceFirst('liability_', '');
                        final accState = context.read<AccountCubit>().state;
                        if (accState is AccountLoaded) {
                          _transferTargetAccount = accState.accounts.firstWhere(
                            (a) => a.id == liabilityId,
                            orElse: () => accState.accounts.first,
                          );
                        }
                      } else {
                        _transferTargetAccount = null;
                      }
                    });
                  },
                ),

                // Step 3 — Account
                _Step3Account(
                  selectedAccount: _selectedAccount,
                  excludedAccountId: _transferTargetAccount?.id,
                  onAccountTap: (acc) {
                    setState(() => _selectedAccount = acc);
                    _advance();
                  },
                ),

                // Step 4 — Title & Date
                _Step4TitleDate(
                  titleController: _titleController,
                  selectedDate:    _selectedDate,
                  onDateTap:       _pickDate,
                  recurrenceFrequency: _recurrenceFrequency,
                  onRecurrenceChanged: (val) {
                    setState(() => _recurrenceFrequency = val);
                  },
                  isIncome: _isIncome,
                  onNext:   _advance,
                  selectedCategory: _selectedCategory,
                  selectedSubCategory: _subCategoryController.text.trim().isEmpty ? null : _subCategoryController.text.trim(),
                ),

                // Step 5 — Amount
                _Step5Amount(
                  isIncome:          _isIncome,
                  amountController:  _amountController,
                  isSaving:          _isSaving,
                  onSave:            _save,
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const _StepProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final progress = (step + 1) / total;

    return Column(
      children: [
        // Dot indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: List.generate(total, (i) {
              final active  = i == step;
              final done    = i < step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  decoration: BoxDecoration(
                    color: done || active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Step 1: Transaction Type ─────────────────────────────────────────────────

class _Step1Type extends StatelessWidget {
  final void Function(bool isIncome, bool isFixedExpense) onSelected;
  final void Function(TransactionEntity) onFavoriteTapped;

  const _Step1Type({
    required this.onSelected,
    required this.onFavoriteTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you recording?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the transaction type to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),

          // Type cards — full-width, stacked
          _TypeCard(
            emoji: '💸',
            label: 'Expense',
            sublabel: 'Money going out',
            color: AppTheme.expenseColor,
            onTap: () => onSelected(false, false),
          ),
          const SizedBox(height: 16),
          _TypeCard(
            emoji: '💰',
            label: 'Income',
            sublabel: 'Money coming in',
            color: AppTheme.incomeColor,
            onTap: () => onSelected(true, false),
          ),
          const SizedBox(height: 16),
          _TypeCard(
            emoji: '🔒',
            label: 'Planned Fixed Expense',
            sublabel: 'Mandatory planned overhead',
            color: theme.colorScheme.primary,
            onTap: () => onSelected(false, true),
          ),
          const SizedBox(height: 48),

          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              if (txState is! TransactionLoaded) return const SizedBox.shrink();
              final favorites = txState.transactions.where((t) => t.isFavorite).toList();
              
              if (favorites.isEmpty) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorite Templates',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: favorites.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) {
                        final fav = favorites[i];
                        return _FavoriteTemplateCard(
                          transaction: fav,
                          onTap: () => onFavoriteTapped(fav),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 2: Category ─────────────────────────────────────────────────────────

class _Step2Category extends StatefulWidget {
  final Category selectedCategory;
  final bool categoryExplicitlySet;
  final bool isIncome;
  final ValueChanged<Category> onCategoryTap;
  final TextEditingController subCategoryController;
  final VoidCallback onNext;
  final String? selectedAccountId;

  const _Step2Category({
    required this.selectedCategory,
    required this.categoryExplicitlySet,
    required this.isIncome,
    required this.onCategoryTap,
    required this.subCategoryController,
    required this.onNext,
    this.selectedAccountId,
  });

  @override
  State<_Step2Category> createState() => _Step2CategoryState();
}

class _Step2CategoryState extends State<_Step2Category> {
  bool _showingSubcategories = false;

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
                  widget.onCategoryTap(updated);
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

  void _removeSubcategory(BuildContext context, Category category, String sub) {
    final updatedList = List<String>.from(category.subcategories)..remove(sub);
    final updated = category.copyWith(subcategories: updatedList);
    context.read<CategoryCubit>().updateCategory(updated);
    widget.onCategoryTap(updated);
    if (widget.subCategoryController.text == sub) {
      widget.subCategoryController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _SectionHeader(
            label: _showingSubcategories ? widget.selectedCategory.name : 'Category',
            hint: widget.categoryExplicitlySet && !_showingSubcategories
                ? null
                : (_showingSubcategories ? 'Pick a subcategory' : 'Pick one to continue'),
          ),
          const SizedBox(height: 12),
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              List<Category> allCategories = DefaultCategories.all;
              if (state is CategoryLoaded) {
                allCategories = state.categories;
              }
              final categories = allCategories.where((c) => c.isIncome == widget.isIncome).toList();

              if (!widget.isIncome) {
                final accState = context.read<AccountCubit>().state;
                if (accState is AccountLoaded) {
                  // Exclude the account selected as SOURCE so you can't pay a card with itself
                  final liabilities = accState.accounts.where(
                    (a) => a.type == AccountType.liability && a.id != widget.selectedAccountId,
                  );
                  for (final acc in liabilities) {
                    categories.add(Category(
                      id: 'liability_${acc.id}',
                      name: acc.name,
                      icon: '💳',
                      color: Colors.orange,
                      isIncome: false,
                    ));
                  }
                }
              }

              // Make sure we have the latest instance of the selected category from the state
              Category currentSelected = widget.selectedCategory;
              if (categories.any((c) => c.id == widget.selectedCategory.id)) {
                currentSelected = categories.firstWhere((c) => c.id == widget.selectedCategory.id);
              }

              if (_showingSubcategories) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentSelected.subcategories.length + 2, // +1 for Back, +1 for Add
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _CategoryCell(
                        category: Category(
                          id: 'back',
                          name: 'Categories',
                          icon: '🗂️',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        isSelected: false,
                        onTap: () {
                          setState(() {
                            _showingSubcategories = false;
                            widget.subCategoryController.clear();
                          });
                        },
                      );
                    }
                    if (i == currentSelected.subcategories.length + 1) {
                      return _CategoryCell(
                        category: Category(
                          id: 'add_sub',
                          name: 'Add New',
                          icon: '➕',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        isSelected: false,
                        onTap: () => _addSubcategory(context, currentSelected),
                      );
                    }
                    
                    final sub = currentSelected.subcategories[i - 1];
                    final isSelected = widget.subCategoryController.text == sub;
                    return _CategoryCell(
                      category: Category(
                        id: 'sub_$i',
                        name: sub,
                        icon: '↳',
                        color: currentSelected.color,
                      ),
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          widget.subCategoryController.text = sub;
                        });
                        widget.onNext();
                      },
                      onLongPress: () async {
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
                          _removeSubcategory(context, currentSelected, sub);
                        }
                      },
                    );
                  },
                );
              }

              // Main Categories View
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (_, i) {
                  if (i == categories.length) {
                    return _CategoryCell(
                      category: Category(
                        id: 'add_new',
                        name: 'Add Custom',
                        icon: '➕',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      isSelected: false,
                      onTap: () async {
                        final newCategory = await showModalBottomSheet<Category>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddCategoryBottomSheet(isIncome: widget.isIncome),
                        );
                        if (newCategory != null) {
                          widget.onCategoryTap(newCategory);
                        }
                      },
                    );
                  }
                  final cat      = categories[i];
                  final selected = cat.id == widget.selectedCategory.id && widget.categoryExplicitlySet;
                  return _CategoryCell(
                    category: cat,
                    isSelected: selected,
                    onTap: () {
                      widget.onCategoryTap(cat);
                      if (cat.id.startsWith('liability_')) {
                        widget.onNext();
                      } else {
                        setState(() {
                          _showingSubcategories = true;
                        });
                      }
                    },
                    onLongPress: cat.isDefault
                        ? null
                        : () async {
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
                          },
                  );
                },
              );
            },
          ),
          // Sub-category input removed entirely per user request
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: widget.categoryExplicitlySet ? widget.onNext : null,
              child: const Text('Next', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Account ──────────────────────────────────────────────────────────

class _Step3Account extends StatelessWidget {
  final AccountEntity? selectedAccount;
  final String? excludedAccountId;
  final ValueChanged<AccountEntity> onAccountTap;

  const _Step3Account({
    required this.selectedAccount,
    this.excludedAccountId,
    required this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            label: 'Account',
            hint: selectedAccount == null ? 'Pick one to continue' : null,
          ),
          const SizedBox(height: 12),
          BlocBuilder<AccountCubit, AccountState>(
            builder: (context, state) {
              if (state is AccountLoaded && state.accounts.isNotEmpty) {
                final availableAccounts = state.accounts.where((acc) => acc.id != excludedAccountId).toList();
                
                if (availableAccounts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No other accounts available to pay from.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return Column(
                  children: availableAccounts.map((acc) {
                    final selected = acc.id == selectedAccount?.id;
                    return _AccountRow(
                      account:    acc,
                      isSelected: selected,
                      onTap:      () => onAccountTap(acc),
                    );
                  }).toList(),
                );
              }
              return Text(
                'No accounts found. Please add an account first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? hint;

  const _SectionHeader({required this.label, this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hint!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _CategoryCell({
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTapDown: (_) => onLongPress?.call(), // More reliable on web
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AccountEntity account;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountRow({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isAsset = account.type == AccountType.asset;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isAsset ? Colors.teal : Colors.orange).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAsset
                    ? Icons.account_balance_wallet_rounded
                    : Icons.credit_card_rounded,
                size: 20,
                color: isAsset ? Colors.teal : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: theme.textTheme.bodyLarge),
                  Text(
                    AppFormatters.formatCurrency(account.balance),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 4: Title & Date ─────────────────────────────────────────────────────

class _Step4TitleDate extends StatelessWidget {
  final TextEditingController titleController;
  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final VoidCallback onNext;
  final String? recurrenceFrequency;
  final ValueChanged<String?> onRecurrenceChanged;
  final bool isIncome;
  final Category selectedCategory;
  final String? selectedSubCategory;

  const _Step4TitleDate({
    required this.titleController,
    required this.selectedDate,
    required this.onDateTap,
    required this.onNext,
    this.recurrenceFrequency,
    required this.onRecurrenceChanged,
    required this.isIncome,
    required this.selectedCategory,
    this.selectedSubCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<TransactionCubit, TransactionState>(
                    builder: (context, state) {
                      if (state is TransactionLoaded) {
                        final recurringMatches = state.transactions.where((t) =>
                            t.recurrenceFrequency != null &&
                            t.nextDueDate != null &&
                            t.categoryId == selectedCategory.id &&
                            t.subCategory == selectedSubCategory).toList();

                        if (recurringMatches.isNotEmpty) {
                          recurringMatches.sort((a, b) => b.nextDueDate!.compareTo(a.nextDueDate!));
                          final latest = recurringMatches.first;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event_repeat_rounded, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Next Scheduled Date',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'A past recurring log for ${selectedSubCategory ?? selectedCategory.name} is due next on ${AppFormatters.formatDate(latest.nextDueDate!)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Text('Add a title', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Give this transaction a short, clear name.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title field
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Groceries, Salary, Netflix…',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    onSubmitted: (_) => onNext(),
                  ),
                  const SizedBox(height: 20),

                  // Date picker row
                  Text('Date', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onDateTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppFormatters.formatRelativeDate(selectedDate),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Text('Recurring Expense?', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: recurrenceFrequency ?? 'None',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.autorenew_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'None', child: Text('No, one-time')),
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                    ],
                    onChanged: onRecurrenceChanged,
                  ),

                  if (recurrenceFrequency != null && recurrenceFrequency != 'None') ...[
                    const SizedBox(height: 24),
                    RecurringTimelineWidget(
                      events: _generatePreviewEvents(selectedDate, recurrenceFrequency!),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  List<RecurringBranchEvent> _generatePreviewEvents(DateTime start, String freq) {
    DateTime next1;
    DateTime next2;
    switch (freq) {
      case 'Daily':
        next1 = start.add(const Duration(days: 1));
        next2 = start.add(const Duration(days: 2));
        break;
      case 'Weekly':
        next1 = start.add(const Duration(days: 7));
        next2 = start.add(const Duration(days: 14));
        break;
      case 'Yearly':
        next1 = DateTime(start.year + 1, start.month, start.day);
        next2 = DateTime(start.year + 2, start.month, start.day);
        break;
      case 'Monthly':
      default:
        next1 = DateTime(start.year, start.month + 1, start.day);
        next2 = DateTime(start.year, start.month + 2, start.day);
        break;
    }
    return [
      RecurringBranchEvent(
        expectedDate: start,
        actualDate: start,
        isPaid: true,
        statusText: 'Paid',
        statusColor: Colors.green,
      ),
      RecurringBranchEvent(
        expectedDate: next1,
        statusText: 'Pending',
        statusColor: Colors.grey,
      ),
      RecurringBranchEvent(
        expectedDate: next2,
        statusText: 'Pending',
        statusColor: Colors.grey,
      ),
    ];
  }
}

// ─── Step 5: Amount ───────────────────────────────────────────────────────────

class _Step5Amount extends StatelessWidget {
  final bool isIncome;
  final TextEditingController amountController;
  final bool isSaving;
  final VoidCallback onSave;

  const _Step5Amount({
    required this.isIncome,
    required this.amountController,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final accentColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final prefix      = isIncome ? '+Rs ' : '-Rs ';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter the amount', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            isIncome ? 'How much did you receive?' : 'How much did you spend?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),

          // Large amount display built from the text field value
          Center(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: amountController,
              builder: (_, val, __) {
                final display =
                    val.text.isEmpty || val.text == '0' ? '0' : val.text;
                return Text(
                  '$prefix$display',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Amount text field — autofocus brings up native keyboard
          TextField(
            controller: amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: isIncome ? '+' : '-',
              prefixStyle: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            onSubmitted: (_) => onSave(),
          ),

          const Spacer(),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Transaction',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteTemplateCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onTap;

  const _FavoriteTemplateCard({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = DefaultCategories.all.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => DefaultCategories.all.last,
    );
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 24)),
            const Spacer(),
            Text(
              (transaction.subCategory != null && transaction.subCategory!.isNotEmpty)
                  ? transaction.subCategory!
                  : transaction.title,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.formatCurrency(transaction.amount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: transaction.isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteAccountPickerSheet extends StatefulWidget {
  final TransactionEntity favorite;
  final void Function(double amount, AccountEntity account) onSave;

  const _FavoriteAccountPickerSheet({
    required this.favorite,
    required this.onSave,
  });

  @override
  State<_FavoriteAccountPickerSheet> createState() => _FavoriteAccountPickerSheetState();
}

class _FavoriteAccountPickerSheetState extends State<_FavoriteAccountPickerSheet> {
  late TextEditingController _amountController;
  AccountEntity? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.favorite.amount.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Quick Save: ${widget.favorite.title}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Account',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                if (state is! AccountLoaded) return const Center(child: CircularProgressIndicator());
                final accounts = state.accounts;
                if (accounts.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Text('No accounts found.'));
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  itemBuilder: (ctx, i) {
                    final acc = accounts[i];
                    final isSelected = _selectedAccount?.id == acc.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Color(acc.colorValue).withOpacity(0.1),
                        child: Text(
                          acc.name.isNotEmpty ? acc.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                          ),
                        ),
                      ),
                      title: Text(acc.name, style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: Text(AppFormatters.formatCurrency(acc.balance)),
                      trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                      onTap: () => setState(() => _selectedAccount = acc),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _selectedAccount == null
                      ? null
                      : () {
                          final amt = double.tryParse(_amountController.text) ?? widget.favorite.amount;
                          widget.onSave(amt, _selectedAccount!);
                        },
                  child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
