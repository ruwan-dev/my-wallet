import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/premium_aurora_vector_background.dart';
import '../../../expenses/presentation/bloc/transaction_cubit.dart';
import '../../../expenses/presentation/bloc/transaction_state.dart';
import '../../../expenses/presentation/bloc/category_cubit.dart';
import '../../../expenses/presentation/bloc/category_state.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../../core/bloc/settings_cubit.dart';
import '../../../../core/bloc/settings_state.dart';
import '../widgets/barefoot_settings_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final txState = context.watch<TransactionCubit>().state;
    final catState = context.watch<CategoryCubit>().state;

    double totalIncome = 0;
    double spentDailyExpenses = 0;
    double spentSplurge = 0;
    double spentSmile = 0;
    double spentFire = 0;

    // Mojo is all time
    double spentMojoAllTime = 0;

    // Grow is all time
    double spentGrowAllTime = 0;

    if (txState is TransactionLoaded && catState is CategoryLoaded) {
      final now = DateTime.now();

      // Calculate all-time Mojo and Grow
      for (final tx in txState.transactions) {
        if (!tx.isIncome) {
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
          if (tx.bucketType == null && tx.subCategory != null &&
              category.subcategoryBuckets.containsKey(tx.subCategory)) {
            bucket = category.subcategoryBuckets[tx.subCategory]!;
          }
          if (bucket == BucketType.mojo) {
            spentMojoAllTime += tx.amount;
          } else if (bucket == BucketType.grow) {
            spentGrowAllTime += tx.amount;
          }
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
          if (tx.bucketType == null && tx.subCategory != null &&
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

    // Balance is negative spent because expenses are positive, sweeps are negative expenses.
    final double mojoBalance = -spentMojoAllTime;
    final double growBalance = -spentGrowAllTime;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bucket Allocator',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const BarefootSettingsSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
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
                    allocatedSmile: allocatedSmile,
                    spentSmile: spentSmile,
                    allocatedFire: allocatedFire,
                    spentFire: spentFire,
                    totalRemaining: totalRemaining,
                  ),
                  _buildMojoTab(context, mojoBalance),
                  _buildGrowTab(context, growBalance),
                ],
              ),
            ),
          ],
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
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildSegmentTab(0, 'Blow', Icons.work_outline),
            _buildSegmentTab(1, 'Mojo', Icons.security),
            _buildSegmentTab(2, 'Grow', Icons.eco),
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
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? Colors.white : Colors.white70),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
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
    required double allocatedSmile,
    required double spentSmile,
    required double allocatedFire,
    required double spentFire,
    required double totalRemaining,
  }) {
    final settings = context.watch<SettingsCubit>().state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxHeight < 600;

        Widget content = Column(
          children: [
            // Top Half: Responsive Credit Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 800;
                final int columns = isDesktop ? 4 : 2;
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
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildCreditCard(
                          title: 'Splurge Wallet',
                          icon: Icons.card_giftcard,
                          color: const Color(0xFFEAB308),
                          badgeText: '10%',
                          balance: allocatedSplurge - spentSplurge,
                          cardNumberEnding: '**** 0002',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildCreditCard(
                          title: 'Smile Wallet',
                          icon: Icons.flight_takeoff,
                          color: const Color(0xFF10B981),
                          badgeText: '10%',
                          balance: allocatedSmile - spentSmile,
                          cardNumberEnding: '**** 0003',
                          targetAmount: settings.smileTargetAmount,
                          goalName: settings.smileGoalName,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildCreditCard(
                          title: 'Fire Wallet',
                          icon: Icons.local_fire_department,
                          color: const Color(0xFFEF4444),
                          badgeText: '20%',
                          balance: allocatedFire - spentFire,
                          cardNumberEnding: '**** 0004',
                          isRedirected: settings.fireRedirection !=
                              FireRedirectionTarget.fire,
                          redirectTarget: settings.fireRedirection ==
                                  FireRedirectionTarget.mojo
                              ? 'Mojo'
                              : 'Grow',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Bottom Half: Interactive Donut Chart Tile
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          const Text(
                            '📊 Balance Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Nested',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Interactive Donut Chart
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          final size = math.min(
                              constraints.maxWidth, constraints.maxHeight);
                          return GestureDetector(
                            onTapUp: (details) {
                              final center = Offset(constraints.maxWidth / 2,
                                  constraints.maxHeight / 2);
                              final dx = details.localPosition.dx - center.dx;
                              final dy = details.localPosition.dy - center.dy;
                              final distance = math.sqrt(dx * dx + dy * dy);

                              // Only register taps near the donut ring
                              if (distance < (size / 2) - 80 ||
                                  distance > (size / 2)) {
                                // Tapped outside or in center hole: reset to total
                                setState(() => _selectedBucketIndex = -1);
                                return;
                              }

                              double angle = math.atan2(dy, dx);
                              angle += math.pi / 2; // start from top
                              if (angle < 0) angle += 2 * math.pi;

                              final pct = angle / (2 * math.pi);
                              setState(() {
                                if (pct < 0.60)
                                  _selectedBucketIndex = 0;
                                else if (pct < 0.70)
                                  _selectedBucketIndex = 1;
                                else if (pct < 0.80)
                                  _selectedBucketIndex = 2;
                                else
                                  _selectedBucketIndex = 3;
                              });
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Donut Chart Custom Painter
                                SizedBox(
                                  width: size,
                                  height: size,
                                  child: CustomPaint(
                                    painter: _ConcentricDonutPainter(
                                      dailyExpensesSpentPct:
                                          allocatedDailyExpenses > 0
                                              ? (spentDailyExpenses /
                                                      allocatedDailyExpenses)
                                                  .clamp(0.0, 1.0)
                                              : 0.0,
                                      splurgeSpentPct: allocatedSplurge > 0
                                          ? (spentSplurge / allocatedSplurge)
                                              .clamp(0.0, 1.0)
                                          : 0.0,
                                      smileSpentPct: allocatedSmile > 0
                                          ? (spentSmile / allocatedSmile)
                                              .clamp(0.0, 1.0)
                                          : 0.0,
                                      fireSpentPct: settings.fireRedirection !=
                                              FireRedirectionTarget.fire
                                          ? 1.0
                                          : (allocatedFire > 0
                                              ? (spentFire / allocatedFire)
                                                  .clamp(0.0, 1.0)
                                              : 0.0),
                                      selectedIndex: _selectedBucketIndex,
                                    ),
                                  ),
                                ),

                                // Interactive Center Text
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _selectedBucketIndex == -1
                                      ? Column(
                                          key: const ValueKey('total'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Total Remaining',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              AppFormatters.formatCurrency(
                                                  context, totalRemaining),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        )
                                      : Builder(
                                          key: ValueKey(
                                              'bucket_$_selectedBucketIndex'),
                                          builder: (context) {
                                            String name = '';
                                            IconData icon = Icons.circle;
                                            double allocated = 0;
                                            double spent = 0;

                                            if (_selectedBucketIndex == 0) {
                                              name = 'Daily Exp.';
                                              icon = Icons.home_rounded;
                                              allocated =
                                                  allocatedDailyExpenses;
                                              spent = spentDailyExpenses;
                                            } else if (_selectedBucketIndex ==
                                                1) {
                                              name = 'Splurge';
                                              icon = Icons.card_giftcard;
                                              allocated = allocatedSplurge;
                                              spent = spentSplurge;
                                            } else if (_selectedBucketIndex ==
                                                2) {
                                              name = 'Smile';
                                              icon = Icons.flight_takeoff;
                                              allocated = allocatedSmile;
                                              spent = spentSmile;
                                            } else {
                                              name = 'Fire';
                                              icon =
                                                  Icons.local_fire_department;
                                              allocated = allocatedFire;
                                              spent = spentFire;
                                            }

                                            final remaining = allocated - spent;

                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(icon,
                                                        color: Colors.white,
                                                        size: 16),
                                                    const SizedBox(width: 6),
                                                    Text(name,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Allocated: ${AppFormatters.formatCurrency(context, allocated)}',
                                                    style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 12)),
                                                Text(
                                                    'Spent: -${AppFormatters.formatCurrency(context, spent)}',
                                                    style: const TextStyle(
                                                        color: Colors.redAccent,
                                                        fontSize: 12)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    AppFormatters
                                                        .formatCurrency(
                                                            context, remaining),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            );
                                          }),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem(
                              color: const Color(0xFF3B82F6),
                              label: 'Daily (60%)'),
                          _buildLegendItem(
                              color: const Color(0xFFEAB308),
                              label: 'Splurge (10%)'),
                          _buildLegendItem(
                              color: const Color(0xFF10B981),
                              label: 'Smile (10%)'),
                          _buildLegendItem(
                              color: const Color(0xFFEF4444),
                              label: 'Fire (20%)'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Outer Ring: Allocation',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Inner Ring: Remaining Balance',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        if (isSmallScreen) {
          // Replace Expanded with a fixed height container for scrolling
          return SingleChildScrollView(
            child: SizedBox(
              height: 800, // Fixed total height to allow scrolling
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }

  Widget _buildMojoTab(BuildContext context, double mojoBalance) {
    final double targetGoal = 15000;
    final double progressPct = (mojoBalance / targetGoal).clamp(0.0, 1.0);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              children: [
                _buildMojoCard(balance: mojoBalance, context: context),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_moon_outlined,
                                  color: Colors.amberAccent, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Emergency Safety Net',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '${(progressPct * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Goal: 3 Months of Living Expenses',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progressPct,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFFFD700)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFFF59E0B)
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(context, mojoBalance),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppFormatters.formatCurrency(context, targetGoal),
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.8),
                        const Color(0xFF047857).withOpacity(0.6),
                      ],
                    ),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Grow Wealth',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppFormatters.formatCurrency(context, growBalance),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1),
                          ),
                          const SizedBox(height: 4),
                          const Text('Total Investments',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const Opacity(
                        opacity: 0.2,
                        child: Icon(Icons.show_chart,
                            size: 80, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance,
                        size: 48, color: Colors.white38),
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
                      backgroundColor: const Color(0xFF10B981),
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

  Widget _buildMojoCard(
      {required double balance, required BuildContext context}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.9), // Gold
            const Color(0xFFF59E0B).withOpacity(0.9), // Amber
          ],
        ),
        border:
            Border.all(color: Colors.yellowAccent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mojo Vault (Emergency)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppFormatters.formatCurrency(context, balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Opacity(
            opacity: 0.3,
            child: Icon(Icons.shield, size: 60, color: Colors.white),
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
  }) {
    final bool hasGoal = targetAmount != null && targetAmount > 0;
    final double progress =
        hasGoal ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;

    // When redirected, the card appears disabled
    final Color displayColor = isRedirected ? Colors.grey.shade700 : color;
    final Color textColor = isRedirected ? Colors.white54 : Colors.white;

    return AspectRatio(
      aspectRatio: 1.8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              displayColor.withOpacity(0.9),
              displayColor.withOpacity(0.5),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Watermark Icon
            Positioned(
              right: -20,
              bottom: -10,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),
            // Foreground Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: Colors.white.withOpacity(0.2),
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

                  // Center Balance & Optional Goal Tracker
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              AppFormatters.formatCurrency(
                                  context, isRedirected ? 0 : balance),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          if (hasGoal && !isRedirected) ...[
                            const SizedBox(height: 4),
                            Text(
                              goalName ?? 'Goal',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.black26,
                                color: Colors.white,
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(progress * 100).toInt()}% of ${AppFormatters.formatCurrency(context, targetAmount)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 8),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BAREFOOT',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 9,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.contactless,
                              color: textColor.withOpacity(0.7), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            cardNumberEnding.replaceAll('**** ', '*'),
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcentricDonutPainter extends CustomPainter {
  final double dailyExpensesSpentPct;
  final double splurgeSpentPct;
  final double smileSpentPct;
  final double fireSpentPct;
  final int selectedIndex;

  _ConcentricDonutPainter({
    required this.dailyExpensesSpentPct,
    required this.splurgeSpentPct,
    required this.smileSpentPct,
    required this.fireSpentPct,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerStrokeWidth = 26.0;
    final outerStrokeWidth = 8.0;
    final spacing = 4.0;

    final double gapSweep = 0.05; // gap in radians
    final double totalAvailableSweep = (2 * math.pi) - (4 * gapSweep);

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

    drawBucket(
        0, currentAngle, 0.60, dailyExpensesSpentPct, const Color(0xFF3B82F6));
    currentAngle += (totalAvailableSweep * 0.60) + gapSweep;

    drawBucket(1, currentAngle, 0.10, splurgeSpentPct, const Color(0xFFEAB308));
    currentAngle += (totalAvailableSweep * 0.10) + gapSweep;

    drawBucket(2, currentAngle, 0.10, smileSpentPct, const Color(0xFF10B981));
    currentAngle += (totalAvailableSweep * 0.10) + gapSweep;

    drawBucket(3, currentAngle, 0.20, fireSpentPct, const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant _ConcentricDonutPainter oldDelegate) {
    return oldDelegate.dailyExpensesSpentPct != dailyExpensesSpentPct ||
        oldDelegate.splurgeSpentPct != splurgeSpentPct ||
        oldDelegate.smileSpentPct != smileSpentPct ||
        oldDelegate.fireSpentPct != fireSpentPct ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
