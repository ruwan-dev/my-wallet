import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/responsive_layout.dart';

import '../../../../core/bloc/settings_cubit.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/account_cubit.dart';
import '../bloc/account_state.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../widgets/custom_numeric_keypad.dart';
import '../widgets/bucket_particle_emitter.dart';

// ─── Bucket metadata ────────────────────────────────────────────────────────

class _BucketMeta {
  final BucketType type;
  final String name;
  final String emoji;
  final String? imageAsset;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _BucketMeta({
    required this.type,
    required this.name,
    required this.emoji,
    this.imageAsset,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

const _buckets = [
  _BucketMeta(
    type: BucketType.dailyExpenses,
    name: 'Blow - Daily',
    emoji: '🛒',
    imageAsset: 'assets/images/bucket_daily.png',
    subtitle: 'Everyday living expenses like food, transport & bills (60%).',
    color: Color(0xFF6366F1), // Blue
    icon: Icons.shopping_cart_rounded,
  ),
  _BucketMeta(
    type: BucketType.splurge,
    name: 'Blow - Splurge',
    emoji: '🎉',
    imageAsset: 'assets/images/bucket_splurge.png',
    subtitle: 'Guilt-free fun money for hobbies & entertainment (10%).',
    color: Color(0xFFEAB308), // Yellow
    icon: Icons.celebration_rounded,
  ),
  _BucketMeta(
    type: BucketType.smile,
    name: 'Smile',
    emoji: '😊',
    imageAsset: 'assets/images/bucket_smile.png',
    subtitle: 'Savings for long-term goals like travel or a car (10%).',
    color: Color(0xFF10B981), // Green
    icon: Icons.favorite_rounded,
  ),
  _BucketMeta(
    type: BucketType.fire, // Mapped 'Grow' to the existing 'fire' bucket type
    name: 'Grow',
    emoji: '🌱',
    imageAsset: 'assets/images/bucket_fire.png',
    subtitle: 'Long-term wealth building and investments (20%).',
    color: Color(0xFFEC4899), // Pink
    icon: Icons.trending_up_rounded,
  ),
];

// ─── Main Page ───────────────────────────────────────────────────────────────

class _TemplateMeta {
  final String title;
  final String emoji;
  final String categoryId;
  final BucketType bucketType;

  const _TemplateMeta({
    required this.title,
    required this.emoji,
    required this.categoryId,
    required this.bucketType,
  });
}

const _kTemplates = [
  _TemplateMeta(
    title: 'Groceries',
    emoji: '🛒',
    categoryId: 'food',
    bucketType: BucketType.dailyExpenses,
  ),
  _TemplateMeta(
    title: 'Petrol',
    emoji: '⛽',
    categoryId: 'transport',
    bucketType: BucketType.dailyExpenses,
  ),
  _TemplateMeta(
    title: 'Coffee',
    emoji: '☕',
    categoryId: 'food',
    bucketType: BucketType.splurge,
  ),
];

class AddTransactionPage extends StatefulWidget {
  final TransactionEntity? existingTransaction;

  const AddTransactionPage({super.key, this.existingTransaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStep = 0;

  bool _isIncome = false;
  Category? _selectedCategory;
  BucketType? _selectedBucketType;
  String? _selectedAccountId;

  String _amountStr = '0';
  final _titleController = TextEditingController();

  bool _isSaving = false;

  final GlobalKey<BucketParticleEmitterState> _particleKey = GlobalKey();
  final GlobalKey _containerKey = GlobalKey();
  Offset? _lastTapPosition;

  // Animation controller for the amount display
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        final newStep = _pageController.page!.round();
        if (newStep != _currentStep) {
          setState(() => _currentStep = newStep);
        }
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _isIncome = tx.isIncome;
      _amountStr = tx.amount.toStringAsFixed(2).replaceAll('.00', '');
      _titleController.text = tx.title;
      _selectedBucketType = tx.bucketType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_isIncome && _currentStep == 1) {
      // Skip bucket page for income
      _pageController.animateToPage(
        3,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_isIncome && _currentStep == 3) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _jumpToAmountWithTemplate(_TemplateMeta template) {
    HapticFeedback.mediumImpact();
    
    // Assign first available account
    final accState = context.read<AccountCubit>().state;
    if (accState is AccountLoaded && accState.accounts.isNotEmpty) {
      _selectedAccountId = accState.accounts.first.id;
    }
    
    // Assign category
    final catState = context.read<CategoryCubit>().state;
    if (catState is CategoryLoaded && catState.categories.isNotEmpty) {
      try {
        _selectedCategory = catState.categories.firstWhere(
          (c) => c.name.toLowerCase().contains(template.title.toLowerCase()) || 
                 c.id == template.categoryId,
        );
      } catch (_) {
        _selectedCategory = catState.categories.first;
      }
    }
    
    setState(() {
      _isIncome = false;
      _selectedBucketType = template.bucketType;
      _titleController.text = template.title;
    });
    
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ─── Keypad ─────────────────────────────────────────────────────────────────

  void _onKeyPressed(String key) {
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() {
      if (_amountStr == '0' && key != '.') {
        _amountStr = key;
      } else if (key == '.' && _amountStr.contains('.')) {
        return;
      } else {
        if (_amountStr.contains('.')) {
          final parts = _amountStr.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        _amountStr += key;
      }
    });
  }

  void _onBackspacePressed() {
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() {
      if (_amountStr.length > 1) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      } else {
        _amountStr = '0';
      }
    });
  }

  // ─── Save ───────────────────────────────────────────────────────────────────

  void _save(BuildContext context) {
    if (_isSaving) return;

    final amount = double.tryParse(_amountStr) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }

    if (!_isIncome && _selectedBucketType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a bucket')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an account')),
      );
      return;
    }

    final accState = context.read<AccountCubit>().state;
    if (accState is! AccountLoaded || !accState.accounts.any((a) => a.id == _selectedAccountId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected account is unavailable')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final tx = TransactionEntity(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      accountId: _selectedAccountId!,
      userId: '',
      title: _titleController.text.trim().isEmpty
          ? _selectedCategory!.name
          : _titleController.text.trim(),
      amount: amount,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      date: widget.existingTransaction?.date ?? DateTime.now(),
      isIncome: _isIncome,
      createdAt: widget.existingTransaction?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      bucketType: _selectedBucketType,
      isFixedExpense: false,
    );

    if (widget.existingTransaction == null) {
      context.read<TransactionCubit>().addTransaction(tx);
    } else {
      context
          .read<TransactionCubit>()
          .updateTransaction(widget.existingTransaction!, tx);
    }
    context.pop();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String get _currencySymbol =>
      context.read<SettingsCubit>().state.currencySymbol;

  String get _formattedAmountDisplay {
    return '$_currencySymbol$_amountStr';
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'Transaction Type';
      case 1:
        return 'Category';
      case 2:
        return 'Choose Bucket';
      case 3:
        return 'Enter Amount';
      default:
        return 'Transaction';
    }
  }



  // ─── Progress Bar ─────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    final theme = Theme.of(context);
    // Visible steps: 0=Type, 1=Category, 2=Bucket(expense only), 3=Amount
    // For income: steps 0,1,3 (bucket skipped)
    final totalVisible = _isIncome ? 3 : 4;

    int visualStep;
    if (_isIncome) {
      visualStep = _currentStep == 3 ? 2 : _currentStep;
    } else {
      visualStep = _currentStep;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(totalVisible, (index) {
          final isCompleted = index < visualStep;
          final isActive = index == visualStep;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < totalVisible - 1 ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF7C3AED), // Lavender
                            Color(0xFF3B82F6), // Blue
                          ],
                        )
                      : null,
                  color: isActive
                      ? null
                      : isCompleted
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.6)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF7C3AED).withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Page 1: Type ─────────────────────────────────────────────────────────

  Widget _buildTypePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(
            theme,
            emoji: '💳',
            title: 'What are you recording?',
            subtitle: 'Choose the transaction type to get started.',
          ),
          const SizedBox(height: 32),

          // Expense card
          _buildTypeCard(
            theme,
            title: 'Expense',
            emoji: '💸',
            color: const Color(0xFFEF4444),
            isSelected: !_isIncome,
            onTap: () {
              setState(() {
                _isIncome = false;
                _selectedCategory = null;
              });
              Future.delayed(const Duration(milliseconds: 120), _nextPage);
            },
          ),

          const SizedBox(height: 16),

          // Income card
          _buildTypeCard(
            theme,
            title: 'Income',
            emoji: '💰',
            color: const Color(0xFF10B981),
            isSelected: _isIncome,
            onTap: () {
              setState(() {
                _isIncome = true;
                _selectedCategory = null;
                _selectedBucketType = null;
              });
              Future.delayed(const Duration(milliseconds: 120), _nextPage);
            },
          ),

          const SizedBox(height: 32),
          _buildFavoriteTemplates(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFavoriteTemplates(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorite Templates',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kTemplates.map((template) {
            return InkWell(
              onTap: () => _jumpToAmountWithTemplate(template),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(template.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      template.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    ThemeData theme, {
    required String title,
    required String emoji,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surface.withValues(alpha: 0.9)
              : theme.colorScheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.8)
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Emoji badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : theme.colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }


  // ─── Page 2: Category ────────────────────────────────────────────────────

  Widget _buildCategoryPage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildPageHeader(
            theme,
            emoji: _isIncome ? '📥' : '📤',
            title: 'Pick a Category',
            subtitle: _isIncome
                ? 'Where is this income coming from?'
                : 'What did you spend on?',
            chipLabel: 'Tap to continue',
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, catState) {
              if (catState is! CategoryLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = catState.categories
                  .where((c) => c.isIncome == _isIncome)
                  .toList();

              if (categories.isEmpty) {
                return Center(
                  child: Text(
                    'No categories found.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 110,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];
                  final isSelected = _selectedCategory?.id == c.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedCategory = c);
                      Future.delayed(
                          const Duration(milliseconds: 150), _nextPage);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? c.color.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            border: Border.all(
                              color: isSelected
                                  ? c.color.withValues(alpha: 0.6)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.color.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              c.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            c.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? c.color
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Page 3: Account & Bucket ─────────────────────────────────────────────

  Widget _buildAccountAndBucketPage(ThemeData theme) {
    if (_isIncome) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buckets section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Assign to Bucket',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _buckets.length,
                    itemBuilder: (context, index) {
                      final meta = _buckets[index];
                      final isSelected = _selectedBucketType == meta.type;
                      return _buildCompactBucketCard(
                        theme,
                        meta: meta,
                        isSelected: isSelected,
                        onTapDown: (details) {
                          _lastTapPosition = details.globalPosition;
                        },
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedBucketType = meta.type);
                          if (_lastTapPosition != null) {
                            final renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              final localPosition = renderBox.globalToLocal(_lastTapPosition!);
                              _particleKey.currentState?.emit(localPosition, meta.type);
                            }
                          }
                          Future.delayed(const Duration(milliseconds: 400), _nextPage);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountChip(ThemeData theme, dynamic account, bool isSelected) {
    final color = Color(account.colorValue);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedAccountId = account.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.15),
                    theme.colorScheme.surface.withValues(alpha: 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_rounded,
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                account.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBucketCard(
    ThemeData theme, {
    required _BucketMeta meta,
    required bool isSelected,
    required VoidCallback onTap,
    required void Function(TapDownDetails) onTapDown,
  }) {
    return GestureDetector(
      onTapDown: onTapDown,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isSelected ? 1.0 : 0.8,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: isSelected ? 1.1 : 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: meta.color.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 8,
                      )
                    ] : [],
                  ),
                  child: meta.imageAsset != null
                      ? Image.asset(
                          meta.imageAsset!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontSize: isSelected ? 80 : 64,
                                height: 1.0,
                              ),
                              child: Center(child: Text(meta.emoji)),
                            );
                          },
                        )
                      : AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: isSelected ? 80 : 64,
                            height: 1.0,
                          ),
                          child: Center(child: Text(meta.emoji)),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meta.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? meta.color : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                meta.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9.5,
                  height: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 4: Amount ──────────────────────────────────────────────────────

  Widget _buildAmountPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accounts section
          Text(
            'Pay From',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52, // Reduced height since we removed the balance text
            child: BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                if (state is AccountLoaded) {
                  final validAccounts = state.accounts.where((a) => a.balance != 0).toList();
                  if (validAccounts.isEmpty) {
                    return Center(
                      child: Text(
                        'No accounts with funds available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: validAccounts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final acc = validAccounts[index];
                      final isSelected = _selectedAccountId == acc.id;
                      return _buildAccountChip(theme, acc, isSelected);
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          
          // Amount display area
          Expanded(
            flex: 2,
            child: Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formattedAmountDisplay,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Keypad area
          Expanded(
            flex: 3,
            child: CustomNumericKeypad(
              onKeyPressed: _onKeyPressed,
              onBackspacePressed: _onBackspacePressed,
            ),
          ),
          
          const SizedBox(height: 16),
          _buildSaveButton(theme),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildContextChip(
    ThemeData theme, {
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB39DDB), // Lavender lighter
            Color(0xFF9575CD), // Lavender darker
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9575CD).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _isSaving ? null : () => _save(context),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        widget.existingTransaction == null
                            ? 'Save Transaction'
                            : 'Update Transaction',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Shared Helpers ──────────────────────────────────────────────────────

  Widget _buildPageHeader(
    ThemeData theme, {
    required String emoji,
    required String title,
    required String subtitle,
    String? chipLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (chipLabel != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBucketColor(BucketType b) {
    switch (b) {
      case BucketType.dailyExpenses:
        return const Color(0xFF6366F1);
      case BucketType.splurge:
        return const Color(0xFFEAB308);
      case BucketType.smile:
        return const Color(0xFF10B981);
      case BucketType.fire:
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _getBucketEmoji(BucketType b) {
    switch (b) {
      case BucketType.dailyExpenses:
        return '🛒';
      case BucketType.splurge:
        return '🎉';
      case BucketType.smile:
        return '😊';
      case BucketType.fire:
        return '🔥';
      default:
        return '🪣';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                ),
                onPressed: _previousPage,
              )
            : const SizedBox.shrink(),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            _getAppBarTitle(),
            key: ValueKey(_currentStep),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                key: _containerKey,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    _buildProgressBar(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildTypePage(theme),
                          _buildCategoryPage(theme),
                          _buildAccountAndBucketPage(theme),
                          _buildAmountPage(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: BucketParticleEmitter(key: _particleKey),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
