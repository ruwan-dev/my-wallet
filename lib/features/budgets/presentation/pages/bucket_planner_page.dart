import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/premium_aurora_vector_background.dart';
import '../../../expenses/presentation/bloc/transaction_cubit.dart';
import '../../../expenses/presentation/bloc/transaction_state.dart';
import '../../../expenses/presentation/bloc/category_cubit.dart';
import '../../../expenses/presentation/bloc/category_state.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/domain/entities/transaction.dart';
import '../../../expenses/presentation/bloc/account_cubit.dart';
import '../../../expenses/presentation/bloc/account_state.dart';
import '../../../expenses/domain/entities/account.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../../core/bloc/settings_cubit.dart';
import '../../../../core/bloc/settings_state.dart';
import '../../../debts/presentation/bloc/debt_cubit.dart';
import '../../../debts/presentation/bloc/debt_state.dart';
import '../../../debts/presentation/widgets/debt_card.dart';
import '../../../debts/presentation/widgets/debt_timeline.dart';
import '../../../debts/presentation/widgets/inline_debt_editor.dart';
import '../widgets/inline_fund_editor.dart';

import '../bloc/custom_budget_cubit.dart';
import '../bloc/custom_budget_state.dart';
import '../widgets/barefoot_settings_sheet.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';

class BucketPlannerPage extends StatefulWidget {
  const BucketPlannerPage({super.key});

  @override
  State<BucketPlannerPage> createState() => _BucketPlannerPageState();
}

class _BucketPlannerPageState extends State<BucketPlannerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _selectedMainTab = 0; // 0=Blow, 1=Mojo, 2=Grow
  int _selectedBucketIndex =
      -1; // -1 for Total, 0=Daily Expenses, 1=Splurge, 2=Smile, 3=Fire
  bool _isAddingDebt = false;
  bool _isAddingMojoFunds = false;
  bool _showSinhalaPhilosophy = false;

  // ── Account Sync ────────────────────────────────────────────────────────
  void _showLinkAccountSheet(
      BuildContext context, String bucketTypeName, Color themeColor) {
    final accState = context.read<AccountCubit>().state;
    final accounts =
        accState is AccountLoaded ? accState.accounts : <dynamic>[];
    final settings = context.read<SettingsCubit>().state;
    final linkedId = settings.bucketAccountLinks[bucketTypeName];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: const Color(0xFF3AAFA9).withOpacity(0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sync Account to Bucket',
                style: TextStyle(
                  color: themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'One account can only be linked to one bucket at a time.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              if (accounts.isEmpty)
                const Text(
                  'No accounts found. Create an account first.',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ...accounts.map((acc) {
                  final isLinked = linkedId == acc.id;
                  return GestureDetector(
                    onTap: () {
                      if (isLinked) {
                        context
                            .read<SettingsCubit>()
                            .unlinkAccountFromBucket(bucketTypeName);
                      } else {
                        context
                            .read<SettingsCubit>()
                            .linkAccountToBucket(bucketTypeName, acc.id);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isLinked
                            ? themeColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLinked
                              ? themeColor.withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: themeColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  AppFormatters.formatCurrency(
                                      context, acc.balance),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isLinked)
                            Icon(Icons.link_rounded,
                                color: themeColor, size: 20)
                          else
                            const Icon(Icons.link_off_rounded,
                                color: Colors.white30, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              if (linkedId != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    context
                        .read<SettingsCubit>()
                        .unlinkAccountFromBucket(bucketTypeName);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_off_rounded,
                            color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Remove Link',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _selectedMainTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _addMojoFunds(double amount, String sourceId) {
    final catState = context.read<CategoryCubit>().state;
    Category? mojoCategory;
    if (catState is CategoryLoaded) {
      mojoCategory = catState.categories.cast<Category?>().firstWhere(
            (c) => c!.bucketType == BucketType.mojo,
            orElse: () => null,
          );
    }

    final accountState = context.read<AccountCubit>().state;
    String accId = 'planned';
    if (accountState is AccountLoaded && accountState.accounts.isNotEmpty) {
      accId = accountState.accounts.first.id;
    }

    final now = DateTime.now();
    final tx = TransactionEntity(
      id: now.millisecondsSinceEpoch.toString(),
      accountId: accId,
      userId: '',
      title: 'Manual Mojo Deposit',
      amount: amount,
      categoryId: mojoCategory?.id ?? 'mojo_fallback',
      categoryName: mojoCategory?.name ?? 'Mojo Deposit',
      date: now,
      isIncome: true,
      note: 'Added funds to Mojo Vault manually',
      createdAt: now,
      updatedAt: now,
      bucketType: BucketType.mojo,
    );

    TransactionEntity? sourceTx;
    if (sourceId == 'bucket_fire') {
      sourceTx = TransactionEntity(
         id: (now.millisecondsSinceEpoch + 1).toString(),
         accountId: accId,
         userId: '',
         title: 'Transfer to Mojo',
         amount: amount,
         categoryId: 'transfer',
         categoryName: 'Transfer',
         date: now,
         isIncome: false,
         note: 'Transferred to Mojo',
         createdAt: now,
         updatedAt: now,
         bucketType: BucketType.fire,
      );
    } else if (sourceId == 'bucket_smile') {
      sourceTx = TransactionEntity(
         id: (now.millisecondsSinceEpoch + 1).toString(),
         accountId: accId,
         userId: '',
         title: 'Transfer to Mojo',
         amount: amount,
         categoryId: 'transfer',
         categoryName: 'Transfer',
         date: now,
         isIncome: false,
         note: 'Transferred to Mojo',
         createdAt: now,
         updatedAt: now,
         bucketType: BucketType.smile,
      );
    } else {
      sourceTx = TransactionEntity(
         id: (now.millisecondsSinceEpoch + 1).toString(),
         accountId: sourceId,
         userId: '',
         title: 'Transfer to Mojo',
         amount: amount,
         categoryId: 'transfer',
         categoryName: 'Transfer',
         date: now,
         isIncome: false,
         note: 'Transferred to Mojo',
         createdAt: now,
         updatedAt: now,
      );
    }

    context.read<TransactionCubit>().addTransaction(tx);
    context.read<TransactionCubit>().addTransaction(sourceTx);
  }

  @override
  Widget build(BuildContext context) {
    final txState = context.watch<TransactionCubit>().state;
    final catState = context.watch<CategoryCubit>().state;
    final budgetState = context.watch<CustomBudgetCubit>().state;

    double totalIncome = 0;
    double spentDailyExpenses = 0;
    double spentSplurge = 0;
    double spentSmile = 0;
    double spentFire = 0;

    double calculatedMojo = 0;
    double calculatedGrow = 0;

    final now = DateTime.now();

    if (txState is TransactionLoaded && catState is CategoryLoaded) {
      // Calculate all-time Mojo and Grow
      for (final tx in txState.transactions) {
        final category = catState.categories.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => const Category(
              id: '',
              name: 'Unknown',
              icon: '',
              color: Colors.grey,
              isIncome: false,
              subcategories: []),
        );
        BucketType bucket = tx.bucketType ?? category.bucketType;
        if (tx.bucketType == null &&
            tx.subCategory != null &&
            category.subcategoryBuckets.containsKey(tx.subCategory)) {
          bucket = category.subcategoryBuckets[tx.subCategory]!;
        }

        if (bucket == BucketType.mojo) {
          calculatedMojo += tx.isIncome ? tx.amount : -tx.amount;
        } else if (bucket == BucketType.grow) {
          calculatedGrow += tx.isIncome ? tx.amount : -tx.amount;
        }
      }

      final currentMonthTxs = txState.transactions.where((tx) {
        return tx.date.year == now.year && tx.date.month == now.month;
      }).toList();

      for (final tx in currentMonthTxs) {
        if (tx.isIncome) {
          totalIncome += tx.amount;
        } else {
          final category = catState.categories.firstWhere(
            (c) => c.id == tx.categoryId,
            orElse: () => const Category(
                id: '',
                name: 'Unknown',
                icon: '',
                color: Colors.grey,
                isIncome: false,
                subcategories: []),
          );

          BucketType bucket = tx.bucketType ?? category.bucketType;
          if (tx.bucketType == null &&
              tx.subCategory != null &&
              category.subcategoryBuckets.containsKey(tx.subCategory)) {
            bucket = category.subcategoryBuckets[tx.subCategory]!;
          }

          if (bucket == BucketType.dailyExpenses)
            spentDailyExpenses += tx.amount;
          else if (bucket == BucketType.splurge)
            spentSplurge += tx.amount;
          else if (bucket == BucketType.smile)
            spentSmile += tx.amount;
          else if (bucket == BucketType.fire) spentFire += tx.amount;
        }
      }
    }
    
    // Overarching bucket totals are purely driven by actual transactions.
    
    const double dailyExpensesPct = 0.60;
    const double splurgePct = 0.10;
    const double smilePct = 0.10;
    const double firePct = 0.20;

    final allocatedDailyExpenses = totalIncome * dailyExpensesPct;
    final allocatedSplurge = totalIncome * splurgePct;
    final allocatedSmile = totalIncome * smilePct;
    final allocatedFire = totalIncome * firePct;

    final double totalRemaining = totalIncome -
        (spentDailyExpenses + spentSplurge + spentSmile + spentFire);

    // Balance is calculated from both income and expenses above.
    final double mojoBalance = calculatedMojo;
    final double growBalance = calculatedGrow;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F9F9), // very soft, almost-white cyan
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Bucket Allocator',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildSegmentedControl(context),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _selectedMainTab = index);
                  },
                  children: [
                    _buildBlowTab(
                      context: context,
                      allocatedDailyExpenses: allocatedDailyExpenses,
                      spentDailyExpenses: spentDailyExpenses,
                      allocatedSplurge: allocatedSplurge,
                      spentSplurge: spentSplurge,
                      totalRemaining: totalRemaining,
                    ),
                    _buildSmileTab(
                      context: context,
                      allocatedSmile: allocatedSmile,
                      spentSmile: spentSmile,
                    ),
                    _buildFireTab(
                      context: context,
                      allocatedFire: allocatedFire,
                      spentFire: spentFire,
                    ),
                    _buildMojoTab(
                      context, 
                      mojoBalance, 
                      allocatedDailyExpenses, 
                      allocatedFire - spentFire, 
                      allocatedSmile - spentSmile
                    ),
                    _buildGrowTab(context, growBalance),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildSegmentTab(0, 'Blow', Icons.work_outline),
            _buildSegmentTab(1, 'Smile', Icons.flight_takeoff),
            _buildSegmentTab(2, 'Fire', Icons.local_fire_department),
            _buildSegmentTab(3, 'Mojo', Icons.security),
            _buildSegmentTab(4, 'Grow', Icons.eco),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(int index, String title, IconData icon) {
    final isSelected = _selectedMainTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 13,
                  color: isSelected ? Colors.black87 : Colors.black45),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.black45,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlowTab({
    required BuildContext context,
    required double allocatedDailyExpenses,
    required double spentDailyExpenses,
    required double allocatedSplurge,
    required double spentSplurge,
    required double totalRemaining,
  }) {
    final settings = context.watch<SettingsCubit>().state;

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = Column(
          children: [
            // Responsive Credit Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 800;
                final int columns = isDesktop ? 2 : 1;
                final double spacing = 12.0;
                final double horizontalPadding = 40.0;
                final double totalSpacing = spacing * (columns - 1);
                final double cardWidth =
                    (constraints.maxWidth - horizontalPadding - totalSpacing) /
                        columns;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildCreditCard(
                          title: 'Daily Expenses',
                          icon: Icons.home_rounded,
                          color: const Color(0xFF3B82F6),
                          badgeText: '60%',
                          balance: allocatedDailyExpenses - spentDailyExpenses,
                          cardNumberEnding: '**** 0001',
                          description: 'Things that keep you running.\n• Examples: Utility bills, groceries.',
                          backgroundImagePath: 'assets/images/daily_expenses.png',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildCreditCard(
                          title: 'Splurge Wallet',
                          icon: Icons.card_giftcard,
                          color: const Color(0xFFFFD700),
                          badgeText: '10%',
                          balance: allocatedSplurge - spentSplurge,
                          cardNumberEnding: '**** 0002',
                          description: 'Things you enjoy purely for fun, without any guilt or second-guessing.\n• Examples: Ordering takeout, dining out, fancy coffee, or music festivals.',
                          backgroundImagePath: 'assets/images/splurge.jpg',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );

        return content;
      },
    );
  }

  Widget _buildCurrencyText(double amount, {double mainFontSize = 28, double smallFontSize = 14, Color color = Colors.white}) {
    final formatted = AppFormatters.formatCurrency(context, amount); // e.g. "Rs 57,500.00"
    
    int firstDigitIdx = formatted.indexOf(RegExp(r'\d'));
    if (firstDigitIdx == -1) firstDigitIdx = 0;
    
    int decimalIdx = formatted.lastIndexOf('.');
    if (decimalIdx == -1) decimalIdx = formatted.length;
    
    final symbolPart = formatted.substring(0, firstDigitIdx);
    final mainPart = formatted.substring(firstDigitIdx, decimalIdx);
    final decimalPart = formatted.substring(decimalIdx);
    
    return RichText(
      text: TextSpan(
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        children: [
          TextSpan(text: symbolPart, style: TextStyle(fontSize: smallFontSize)),
          TextSpan(text: mainPart, style: TextStyle(fontSize: mainFontSize)),
          TextSpan(text: decimalPart, style: TextStyle(fontSize: smallFontSize)),
        ],
      ),
    );
  }

  Widget _buildSmileTab({
    required BuildContext context,
    required double allocatedSmile,
    required double spentSmile,
  }) {
    final settings = context.watch<SettingsCubit>().state;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: _buildWideVaultCard(
            context: context,
            bucketTypeName: 'smile',
            title: 'Smile Wallet',
            icon: Icons.flight_takeoff,
            primaryColor: const Color(0xFF34D399),
            secondaryColor: const Color(0xFF10B981),
            balance: allocatedSmile - spentSmile,
            targetAmount: settings.smileTargetAmount,
            goalName: settings.smileGoalName,
            description: 'Things that put a genuine smile on your face.\n• Examples: Weekend getaway trips, new tech gadgets, or special gifts.',
            backgroundImagePath: 'assets/images/smile.jpg',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0)
                .copyWith(top: 16.0),
            child: const Column(
              children: [
                // Future content for Smile Tab can go here
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZeroDebtMessage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildPhilosophyPoint(
             title: 'The Fire Evolves',
             description: _showSinhalaPhilosophy ? 'ගෙවන්න ණය නැති නිසා, ඔයාගේ 20% Fire මුදල සම්පූර්ණයෙන්ම වෙන් වෙන්නේ ධනය ගොඩනගන්නයි.' : 'With zero debt to pay, your 20% Fire allocation is fully unlocked to build your wealth.',
           ),
           const SizedBox(height: 12),
           _buildPhilosophyPoint(
             title: 'Maxing Out Mojo',
             description: _showSinhalaPhilosophy ? 'මාස 3ක හදිසි අරමුදල පිරෙනකම්, අර 20% කෙලින්ම යන්නේ ඔයාගේ Mojo බකට් එකටයි.' : 'That 20% now flows directly into your Mojo bucket until your 3-month emergency safety net is completely full.',
           ),
           const SizedBox(height: 12),
           _buildPhilosophyPoint(
             title: 'Unlocking the Grow Machine',
             description: _showSinhalaPhilosophy ? 'Mojo එක පිරුණු ගමන්, ඒ 20% දිගටම Grow බකට් එකට ගිහින් ස්වයංක්‍රීයව ආයෝජනය වෙනවා.' : 'Once Mojo is full, that same 20% redirects into your Grow bucket to build long-term wealth through automated investments.',
           ),
           const SizedBox(height: 12),
           _buildPhilosophyPoint(
             title: '100% Guilt-Free Spending',
             description: _showSinhalaPhilosophy ? 'කිසිම මානසික පීඩනයක් නැතුව Daily (60%), Splurge (10%), සහ Smile (10%) සල්ලි වලින් ඔයාට උපරිම සතුටක් ගන්න පුළුවන්.' : 'You can fully enjoy your Daily (60%), Splurge (10%), and Smile (10%) money with zero financial stress.',
           ),
           const SizedBox(height: 12),
           _buildPhilosophyPoint(
             title: 'No New Debt',
             description: _showSinhalaPhilosophy ? 'ආපහු හැරී බැලීමක් නැහැ. වාහනයක්, ෆෝන් එකක් වගේ ඕනෑම අලුත් දෙයක් ගන්නේ Smile බකට් එකෙන් සල්ලි එකතු කරලා Cash වලින් විතරයි.' : 'You never look back. Any new purchases (like a car or tech) are saved for via the Smile bucket and bought in cash.',
           ),
           const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               TextButton(
                 onPressed: () => setState(() => _showSinhalaPhilosophy = !_showSinhalaPhilosophy),
                 style: TextButton.styleFrom(
                   foregroundColor: Colors.white54,
                   padding: const EdgeInsets.all(12),
                   shape: const CircleBorder(),
                   backgroundColor: Colors.white.withOpacity(0.1),
                 ),
                 child: Text(_showSinhalaPhilosophy ? 'En' : 'Si', style: const TextStyle(fontWeight: FontWeight.bold)),
               ),
             ],
           ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildPhilosophyPoint({required String title, required String description}) {
    final text = title.isNotEmpty ? '$title - $description' : description;
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildFireTab({
    required BuildContext context,
    required double allocatedFire,
    required double spentFire,
  }) {
    final settings = context.watch<SettingsCubit>().state;
    final fireBalance = allocatedFire - spentFire;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: _buildWideVaultCard(
            context: context,
            bucketTypeName: 'fire',
            title: 'Fire Wallet',
            icon: Icons.local_fire_department,
            primaryColor: const Color(0xFFF87171),
            secondaryColor: const Color(0xFFEF4444),
            balance: fireBalance,
            isRedirected:
                settings.fireRedirection != FireRedirectionTarget.fire,
            redirectTarget:
                settings.fireRedirection == FireRedirectionTarget.mojo
                    ? 'Mojo'
                    : 'Grow',
            description: 'Things that crush your burdens and build your freedom.\n• Examples: Clearing credit card debt and paying off vehicle leases.',
            backgroundImagePath: 'assets/images/fire.jpg',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0)
                .copyWith(top: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trophy Road',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isAddingDebt)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _isAddingDebt = true),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Debt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ),
                if (_isAddingDebt)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: InlineDebtEditor(
                      onCancel: () => setState(() => _isAddingDebt = false),
                      onSave: () => setState(() => _isAddingDebt = false),
                    ),
                  ),
                const SizedBox(height: 16),
                BlocBuilder<DebtCubit, DebtState>(
                  builder: (context, state) {
                    if (state is DebtLoading) {
                      return const ShimmerTile();
                    } else if (state is DebtLoaded) {
                      final debts = state.debts;

                      if (debts.isEmpty) {
                        if (_isAddingDebt) {
                          return const SizedBox.shrink();
                        }
                        return _buildZeroDebtMessage(context);
                      }


                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          DebtTimeline(debts: debts, fireBalance: fireBalance),
                        ],
                      );
                    }
                    return const Text('Failed to load debts.',
                        style: TextStyle(color: Colors.red));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMojoTab(BuildContext context, double mojoBalance,
      double dailyExpensesAllocation, double fireBalance, double smileBalance) {
    final double targetGoal = (dailyExpensesAllocation * 3) > 0
        ? (dailyExpensesAllocation * 3)
        : 15000;
    final double progressPct =
        targetGoal > 0 ? (mojoBalance / targetGoal).clamp(0.0, 1.0) : 0.0;

    final accountState = context.read<AccountCubit>().state;
    List<Map<String, dynamic>> sourceAccounts = [];
    if (accountState is AccountLoaded) {
      for (var acc in accountState.accounts) {
        if (acc.balance > 0) {
          sourceAccounts.add(
              {'id': acc.id, 'name': acc.name, 'balance': acc.balance});
        }
      }
    }
    if (fireBalance > 0) {
      sourceAccounts.add(
          {'id': 'bucket_fire', 'name': 'Fire Vault', 'balance': fireBalance});
    }
    if (smileBalance > 0) {
      sourceAccounts.add({
        'id': 'bucket_smile',
        'name': 'Smile Vault',
        'balance': smileBalance
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: _buildWideVaultCard(
            context: context,
            bucketTypeName: 'mojo',
            title: 'Mojo Vault (Emergency)',
            icon: Icons.security,
            primaryColor: const Color(0xFFFFD700),
            secondaryColor: const Color(0xFFF59E0B),
            balance: mojoBalance,
            targetAmount: targetGoal,
            description:
                'Things that keep you safe when life hits hard.\n• Examples: Unexpected medical bills or emergency car repairs.',
            backgroundImagePath: 'assets/images/mojo.jpg',
            actionWidget: !_isAddingMojoFunds
                ? OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _isAddingMojoFunds = true),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add Funds',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side:
                          const BorderSide(color: Colors.black54, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 28),
                    ),
                  )
                : null,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0)
                .copyWith(top: 16.0),
            child: Column(
              children: [

                if (_isAddingMojoFunds) ...[
                  const SizedBox(height: 16),
                  InlineFundEditor(
                    title: 'Add Funds to Mojo',
                    themeColor: const Color(0xFFF59E0B),
                    sourceAccounts: sourceAccounts,
                    onCancel: () => setState(() => _isAddingMojoFunds = false),
                    onSave: (amount, sourceId) {
                      _addMojoFunds(amount, sourceId);
                      setState(() => _isAddingMojoFunds = false);
                    },
                  ),
                ],
                const SizedBox(height: 48),
                Text(
                  'Keep sweeping your leftover Daily Expenses here!',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowTab(BuildContext context, double growBalance) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: _buildWideVaultCard(
            context: context,
            title: 'Grow Wealth',
            icon: Icons.trending_up,
            primaryColor: const Color(0xFF34D399),
            secondaryColor: const Color(0xFF10B981),
            balance: growBalance,
            description: 'Things that multiply your wealth for the future.\n• Examples: Stock market investments or real estate property purchases.',
            backgroundImagePath: 'assets/images/grow.jpg',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0)
                .copyWith(top: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF50C8C8).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance,
                        size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Net Worth Tracking',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connect your investment accounts, superannuation, and property values to track your long-term wealth growth.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white54, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Investment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF50C8C8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideVaultCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required double balance,
    String? bucketTypeName,   // e.g. 'mojo', 'grow', 'fire', 'smile'
    double? targetAmount,
    String? goalName,
    bool isRedirected = false,
    String? redirectTarget,
    String? description,
    Widget? actionWidget,
    String? backgroundImagePath,
  }) {
    final settings = context.watch<SettingsCubit>().state;
    final accState = context.watch<AccountCubit>().state;

    // Resolve linked account (if any)
    AccountEntity? linkedAccount;
    if (bucketTypeName != null &&
        settings.bucketAccountLinks.containsKey(bucketTypeName) &&
        accState is AccountLoaded) {
      final linkedId = settings.bucketAccountLinks[bucketTypeName]!;
      try {
        linkedAccount = accState.accounts.firstWhere((a) => a.id == linkedId);
      } catch (_) {
        linkedAccount = null;
      }
    }
    final Color displayPrimary =
        isRedirected ? Colors.grey.shade700 : primaryColor;
    final Color displaySecondary =
        isRedirected ? Colors.grey.shade600 : secondaryColor;
    final Color textColor = isRedirected ? Colors.black54 : Colors.black;

    return Container(
      width: double.infinity,
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: backgroundImagePath == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  displayPrimary.withOpacity(0.9),
                  displaySecondary.withOpacity(0.9),
                ],
              )
            : null,
        image: backgroundImagePath != null
            ? DecorationImage(
                image: AssetImage(backgroundImagePath),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              )
            : null,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: textColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRedirected
                            ? '$title (Redirecting to $redirectTarget)'
                            : title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCurrencyText(
                   isRedirected ? 0 : balance,
                   color: textColor,
                   mainFontSize: 28,
                ),
                if (targetAmount != null && targetAmount > 0) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (balance / targetAmount).clamp(0.0, 1.0),
                      backgroundColor: Colors.black.withOpacity(0.1),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.black),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppFormatters.formatCurrency(context, balance)} / ${AppFormatters.formatCurrency(context, targetAmount)}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (actionWidget != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actionWidget,
                  ),
                ],

                // ── Account Sync chip ─────────────────────────────────────
                if (bucketTypeName != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showLinkAccountSheet(
                        context, bucketTypeName, primaryColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: linkedAccount != null
                            ? Colors.black.withOpacity(0.15)
                            : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: linkedAccount != null
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            linkedAccount != null
                                ? Icons.link_rounded
                                : Icons.link_off_rounded,
                            size: 13,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            linkedAccount != null
                                ? '${linkedAccount.name}  •  ${AppFormatters.formatCurrency(context, linkedAccount.balance)}'
                                : 'Sync Account',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (backgroundImagePath == null)
            Opacity(
              opacity: 0.10,
              child: Icon(icon, size: 60, color: Colors.black),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCreditCard({
    required String title,
    required IconData icon,
    required Color color,
    required String badgeText,
    required double balance,
    required String cardNumberEnding,
    double? targetAmount,
    String? goalName,
    bool isRedirected = false,
    String? redirectTarget,
    String? description,
    String? backgroundImagePath,
  }) {
    final bool hasGoal = targetAmount != null && targetAmount > 0;
    final double progress =
        hasGoal ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;

    // When redirected, the card appears disabled
    final Color displayColor = isRedirected ? Colors.grey.shade700 : color;
    final Color textColor = isRedirected ? Colors.black54 : Colors.black;

    return Container(
      width: double.infinity,
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: backgroundImagePath == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  displayColor.withOpacity(0.9),
                  displayColor.withOpacity(0.5),
                ],
              )
            : null,
        image: backgroundImagePath != null
            ? DecorationImage(
                image: AssetImage(backgroundImagePath),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              )
            : null,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Watermark Icon
          if (backgroundImagePath == null)
            Positioned(
              right: -20,
              bottom: -10,
              child: Opacity(
                opacity: 0.10,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.black,
                ),
              ),
            ),
          // Foreground Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(icon, color: textColor, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isRedirected
                                  ? '$title (Redirecting to $redirectTarget)'
                                  : title.replaceAll(' Wallet', ''),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCurrencyText(
                   isRedirected ? 0 : balance,
                   color: textColor,
                   mainFontSize: 28,
                ),
                if (hasGoal && !isRedirected) ...[
                  const SizedBox(height: 16),
                  Text(
                    goalName ?? 'Goal',
                    style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.black12,
                      color: Colors.black87,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(progress * 100).toInt()}% of ${AppFormatters.formatCurrency(context, targetAmount)}',
                    style: TextStyle(
                        color: textColor.withOpacity(0.8), fontSize: 8),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcentricDonutPainter extends CustomPainter {
  final double dailyExpensesSpentPct;
  final double splurgeSpentPct;
  final int selectedIndex;

  _ConcentricDonutPainter({
    required this.dailyExpensesSpentPct,
    required this.splurgeSpentPct,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerStrokeWidth = 26.0;
    final outerStrokeWidth = 8.0;
    final spacing = 4.0;

    final double gapSweep = 0.05; // gap in radians
    final double totalAvailableSweep =
        (2 * math.pi) - (2 * gapSweep); // Only 2 gaps now

    void drawBucket(int index, double startAngle, double percentage,
        double spentPct, Color baseColor) {
      final bucketSweep = totalAvailableSweep * percentage;

      // Determine opacity based on selection
      final bool isTotal = selectedIndex == -1;
      final bool isSelected = selectedIndex == index;

      final double activeOpacity = (isTotal || isSelected) ? 1.0 : 0.3;
      final double inactiveOpacity = (isTotal || isSelected) ? 0.15 : 0.05;

      // Calculate radii
      final outerRadius = (size.width / 2) - (outerStrokeWidth / 2);
      final innerRadius = outerRadius -
          (outerStrokeWidth / 2) -
          spacing -
          (innerStrokeWidth / 2);

      final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

      // --- Outer Ring (Allocation Marker) ---
      final outerPaint = Paint()
        ..color = baseColor.withOpacity(isSelected ? 0.8 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? outerStrokeWidth + 2 : outerStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(outerRect, startAngle, bucketSweep, false, outerPaint);

      // --- Inner Ring (Progress/Remaining vs Spent) ---
      // We draw the remaining portion vibrant, and the spent portion dull.
      final innerPaintRemaining = Paint()
        ..color = baseColor.withOpacity(activeOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? innerStrokeWidth + 4 : innerStrokeWidth
        ..strokeCap = StrokeCap.butt;

      final innerPaintSpent = Paint()
        ..color = baseColor.withOpacity(inactiveOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? innerStrokeWidth + 4 : innerStrokeWidth
        ..strokeCap = StrokeCap.butt;

      final spentSweep = bucketSweep * spentPct;
      final remainingSweep = bucketSweep - spentSweep;

      // Draw remaining part first
      if (remainingSweep > 0) {
        canvas.drawArc(
            innerRect, startAngle, remainingSweep, false, innerPaintRemaining);
      }

      // Draw spent part after the remaining part
      if (spentSweep > 0) {
        canvas.drawArc(innerRect, startAngle + remainingSweep, spentSweep,
            false, innerPaintSpent);
      }
    }

    double currentAngle = -math.pi / 2; // Start at top (12 o'clock)

    // Daily Expenses (scaled to 85% instead of 60%)
    drawBucket(
        0, currentAngle, 0.85, dailyExpensesSpentPct, const Color(0xFF3B82F6));
    currentAngle += (totalAvailableSweep * 0.85) + gapSweep;

    // Splurge (scaled to 15% instead of 10%)
    drawBucket(1, currentAngle, 0.15, splurgeSpentPct, const Color(0xFFEAB308));
  }

  @override
  bool shouldRepaint(covariant _ConcentricDonutPainter oldDelegate) {
    return oldDelegate.dailyExpensesSpentPct != dailyExpensesSpentPct ||
        oldDelegate.splurgeSpentPct != splurgeSpentPct ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
