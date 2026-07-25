import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/account_cubit.dart';
import '../bloc/account_state.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/shimmer_tile.dart';
import '../widgets/transaction_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardPage
// ─────────────────────────────────────────────────────────────────────────────

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<TransactionCubit, TransactionState>(
        listener: (context, state) {
          if (state is TransactionLoaded && state.deletedTransaction != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: const Text('Transaction deleted'),
                action: SnackBarAction(
                  label: 'Close',
                  onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
                duration: const Duration(seconds: 3),
              ));
          }
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            _DashboardAppBar(),

            // ── Balance Card ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, accState) {
                    double totalBalance = 0;
                    double totalIncome  = 0;
                    double totalExpense = 0;

                    if (accState is AccountLoaded) {
                      for (final a in accState.accounts) {
                        totalBalance += a.balance;
                      }
                    }
                    final txState = context.watch<TransactionCubit>().state;
                    if (txState is TransactionLoaded) {
                      for (final tx in txState.transactions) {
                        if (tx.isIncome) totalIncome  += tx.amount;
                        else            totalExpense += tx.amount;
                      }
                    }

                    return _BalanceCard(
                      totalBalance: totalBalance,
                      totalIncome:  totalIncome,
                      totalExpense: totalExpense,
                    );
                  },
                ),
              ),
            ),



            // ── My Accounts Section ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'My Accounts',
                  actionLabel: '',
                  onAction: null,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: BlocBuilder<AccountCubit, AccountState>(
                builder: (context, state) {
                  if (state is AccountLoading) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is AccountLoaded) {
                    return SizedBox(
                      height: 120,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.accounts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            return _AccountCard(account: state.accounts[i], index: i);
                          },
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // ── Gap ────────────────────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Recent Transactions Header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'Recent Transactions',
                  actionLabel: 'See All',
                  onAction: () {},
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Transaction List ───────────────────────────────────────────
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, txState) {
                if (txState is TransactionLoading) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ShimmerTile(),
                      ),
                      childCount: 6,
                    ),
                  );
                }
                if (txState is TransactionLoaded) {
                  if (txState.transactions.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(),
                    );
                  }
                  return BlocBuilder<AccountCubit, AccountState>(
                    builder: (context, accState) {
                      final accounts = accState is AccountLoaded
                          ? accState.accounts
                          : <AccountEntity>[];
                      return SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            _buildGroupedItems(
                                txState.transactions, accounts, context),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-expense'),
        backgroundColor: AppTheme.incomeColor,
        elevation: 3,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  List<Widget> _buildGroupedItems(
    List<TransactionEntity> transactions,
    List<AccountEntity> accounts,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final List<Widget> items = [];
    String? currentGroup;

    for (final tx in transactions) {
      final dateGroup  = AppFormatters.formatRelativeDate(tx.date);
      final accountName = accounts
          .firstWhere(
            (a) => a.id == tx.accountId,
            orElse: () => const AccountEntity(
                id: '', name: 'Unknown', balance: 0,
                type: AccountType.asset, userId: ''),
          )
          .name;

      if (dateGroup != currentGroup) {
        if (items.isNotEmpty) items.add(const SizedBox(height: 8));
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            dateGroup,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ));
        currentGroup = dateGroup;
      }

      items.add(TransactionCard(
        transaction: tx,
        accountName: accountName,
        onDelete: () =>
            context.read<TransactionCubit>().deleteTransaction(tx),
      ));
    }
    return items;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning 👋';
    } else if (hour < 17) {
      greeting = 'Good afternoon 👋';
    } else {
      greeting = 'Good evening 👋';
    }

    return SliverAppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      pinned: true,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text('My Wallet', style: theme.textTheme.titleMedium),
        ],
      ),
      actions: [
        if (FirebaseAuth.instance.currentUser?.email == 'admin@gmail.com')
          IconButton(
            tooltip: 'Data Inspector',
            onPressed: () => GoRouter.of(context).push('/debug'),
            icon: Icon(Icons.bug_report_outlined,
                color: theme.colorScheme.onSurfaceVariant),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthCubit>().logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                FirebaseAuth.instance.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Card
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  const _BalanceCard({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34D399), // lighter mint — top-left
            Color(0xFF059669), // deep teal — bottom-right
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -35, right: 50,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppFormatters.formatCurrency(totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _CardStat(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Income',
                      value: AppFormatters.formatCurrency(totalIncome),
                    ),
                  ),
                  Container(
                      width: 1, height: 36,
                      color: Colors.white.withOpacity(0.2)),
                  Expanded(
                    child: _CardStat(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Expenses',
                      value: AppFormatters.formatCurrency(totalExpense),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CardStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Cards (horizontal)
// ─────────────────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AccountEntity account;
  final int index;

  const _AccountCard({required this.account, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isAsset = account.type == AccountType.asset;

    // Distinct soft pastel colours for each account
    final List<Color> bgColors = [
      const Color(0xFFE8F0FE), // soft blue
      const Color(0xFFFCE8E6), // soft red
      const Color(0xFFE6F4EA), // soft green
      const Color(0xFFFEF7E0), // soft yellow
      const Color(0xFFF3E8FF), // soft purple
    ];
    final bgColor = bgColors[index % bgColors.length];

    final accentColor =
        isAsset ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAsset
                      ? Icons.account_balance_wallet_rounded
                      : Icons.credit_card_rounded,
                  color: accentColor,
                  size: 16,
                ),
              ),
              const Spacer(),
              // Account type chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAsset ? 'Asset' : 'Liability',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            AppFormatters.formatCurrency(account.balance),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            account.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (onAction != null && actionLabel.isNotEmpty)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.incomeColor,
              ),
            ),
          ),
      ],
    );
  }
}
