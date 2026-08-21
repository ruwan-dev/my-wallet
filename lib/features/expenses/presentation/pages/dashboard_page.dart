import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../../core/constants/app_constants.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/sweep_util.dart';
import '../../../../core/bloc/settings_cubit.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/account_cubit.dart';
import '../bloc/account_state.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../bloc/budget_cubit.dart';
import '../bloc/budget_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../../domain/entities/category.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/shimmer_tile.dart';
import '../widgets/transaction_card.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/set_budget_bottom_sheet.dart';
import '../widgets/animated_dashboard_card.dart';
import '../widgets/monthly_budget_progress_card.dart';
import '../pages/budget_setup_page.dart';
// ─────────────────────────────────────────────────────────────────────────────
// DashboardPage
// ─────────────────────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: BlocListener<TransactionCubit, TransactionState>(
        listenWhen: (previous, current) {
          // Listen for sweeps when transactions load, AND listen for deletes
          return current is TransactionLoaded;
        },
        listener: (context, state) {
          if (state is TransactionLoaded) {
            SweepUtil.checkAndTriggerAutoSweep(context);
            
            // To prevent multiple snackbars for the same deletion, we can just rely on the state
            if (state.deletedTransaction != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Transaction deleted'),
                  duration: Duration(seconds: 3),
                ));
              // We should really clear it from state but the cubit handles it after a delay
            }
          }
        },
        child: Container(
          color: const Color(0xFFF2F8F7),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
              // ── Balance Card ───────────────────────────────────────────────
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, accState) {
                    double totalBalance = 0;
                    double totalIncome  = 0;
                    double totalExpense = 0;
                    double fixedExpenses = 0;

                    if (accState is AccountLoaded) {
                      for (final a in accState.accounts) {
                        if (a.type == AccountType.liability) {
                          totalBalance -= a.balance;
                        } else {
                          totalBalance += a.balance;
                        }
                      }
                    }
                    final txState = context.watch<TransactionCubit>().state;
                    if (txState is TransactionLoaded) {
                      fixedExpenses = context.read<TransactionCubit>().currentMonthFixedExpenses;
                      for (final tx in txState.transactions) {
                        if (tx.isIncome) totalIncome  += tx.amount;
                        else            totalExpense += tx.amount;
                      }
                    }

                    return AnimatedDashboardCard(
                      totalBalance: totalBalance,
                      totalIncome:  totalIncome,
                      totalExpense: totalExpense,
                      fixedExpenses: fixedExpenses,
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // ── Planning & Tools ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(
                title: 'Planning & Tools',
                actionLabel: '',
                onAction: null,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fit exactly 4 cards per row, spreading them evenly
                  const int perRow = 4;
                  const double spacing = 12;
                  final double cardWidth =
                      (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

                  Widget toolCard({
                    required String title,
                    required IconData icon,
                    required Color color,
                    required VoidCallback onTap,
                  }) {
                    return SizedBox(
                      width: cardWidth,
                      child: GestureDetector(
                        onTap: onTap,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(icon,
                                    color: const Color(0xFF50C8C8), size: 24),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF6E6E82),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final tools = [
                    toolCard(
                      title: 'Accounts',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF4CAF82),
                      onTap: () => context.push('/accounts'),
                    ),
                    toolCard(
                      title: 'Budgets',
                      icon: Icons.check_box_outlined,
                      color: Colors.blueAccent,
                      onTap: () => context.push('/budgets-main'),
                    ),
                    toolCard(
                      title: 'Analytics',
                      icon: Icons.bar_chart_outlined,
                      color: const Color(0xFFFF8C42),
                      onTap: () => context.push('/analytics'),
                    ),
                    toolCard(
                      title: 'Buckets',
                      icon: Icons.water_drop_outlined,
                      color: const Color(0xFF50C8C8),
                      onTap: () => context.push('/buckets-planner'),
                    ),
                    toolCard(
                      title: 'Recurring',
                      icon: Icons.repeat_rounded,
                      color: const Color(0xFF9B8FD4),
                      onTap: () => context.push('/recurring-bills'),
                    ),
                  ];

                  // Split into rows of perRow
                  final List<Widget> rows = [];
                  for (int i = 0; i < tools.length; i += perRow) {
                    final rowItems = tools.sublist(
                        i, (i + perRow).clamp(0, tools.length));
                    rows.add(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          for (int j = 0; j < rowItems.length; j++) ...[
                            rowItems[j],
                            if (j < rowItems.length - 1)
                              const SizedBox(width: spacing),
                          ],
                        ],
                      ),
                    );
                    if (i + perRow < tools.length) {
                      rows.add(const SizedBox(height: 16));
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),


            // ── Recent Transactions Header ─────────────────────────────────
            Container(
              color: const Color(0xFFF2F8F7),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8, top: 4),
              child: _SectionHeader(
                title: 'Recent Transactions',
                actionLabel: 'See All',
                onAction: () => context.push('/all-transactions'),
              ),
            ),

            // ── Transaction List ───────────────────────────────────────────
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, txState) {
              if (txState is TransactionLoading) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerTile(),
                      ),
                    );
                    }
                  if (txState is TransactionLoaded) {
                    if (txState.transactions.isEmpty) {
                      return const EmptyStateWidget();
                    }
                    return BlocBuilder<AccountCubit, AccountState>(
                      builder: (context, accState) {
                        final accounts = accState is AccountLoaded
                            ? accState.accounts
                            : <AccountEntity>[];
                        // Show a reasonable number of recent transactions since it now scrolls independently
                        final recentTransactions = txState.transactions.take(10).toList();
                      return ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100, top: 8), 
                        children: _buildGroupedItems(
                          recentTransactions, accounts, context),
                      );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
            ),
        ],
      ), // End Column
      ), // End SingleChildScrollView
      ), // End Container
      ), // End BlocListener
      ), // End SafeArea
    ); // End Scaffold
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
      String accountName = tx.accountId == 'planned' 
          ? 'Planned' 
          : accounts
              .firstWhere(
                (a) => a.id == tx.accountId,
                orElse: () => const AccountEntity(
                    id: '', name: 'Unknown', balance: 0,
                    type: AccountType.asset, userId: ''),
              )
              .name;

      if (tx.transferAccountId != null) {
        final targetName = accounts
            .firstWhere(
              (a) => a.id == tx.transferAccountId,
              orElse: () => const AccountEntity(
                  id: '', name: 'Unknown Account', balance: 0,
                  type: AccountType.asset, userId: ''),
            )
            .name;
        accountName = '$accountName → $targetName';
      }

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

class _ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        color: Colors.transparent, // Expand tap area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFF50C8C8), size: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6E6E82),
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFA0AAB2),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        if (onAction != null && actionLabel.isNotEmpty)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF50C8C8).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Color(0xFF50C8C8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
