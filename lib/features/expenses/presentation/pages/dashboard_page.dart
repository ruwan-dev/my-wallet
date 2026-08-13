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
import '../widgets/mesh_account_card.dart';
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

            // ── My Accounts Section ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(
                title: 'My Accounts',
                actionLabel: '',
                onAction: null,
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                if (state is AccountLoading) {
                  return const SizedBox(
                    height: 120,
                    child: const ShimmerTile(),
                  );
                }
                if (state is AccountLoaded) {
                  return SizedBox(
                    height: 100, // Decreased height
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          return MeshAccountCard(account: state.accounts[i]);
                        },
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
            const SizedBox(height: 12),
            SizedBox(
              height: 95,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _ToolCard(
                    title: 'Budgets',
                    icon: Icons.check_box_outlined,
                    color: Colors.blueAccent,
                    onTap: () => context.push('/budgets-main'),
                  ),
                  const SizedBox(width: 12),
                  _ToolCard(
                    title: 'Analytics',
                    icon: Icons.bar_chart_outlined,
                    color: Colors.orangeAccent,
                    onTap: () => context.push('/analytics'),
                  ),
                  const SizedBox(width: 12),
                  _ToolCard(
                    title: 'Buckets',
                    icon: Icons.water_drop_outlined, // or another appropriate icon like an umbrella or wallet
                    color: Colors.tealAccent,
                    onTap: () => context.push('/buckets-planner'),
                  ),
                  const SizedBox(width: 12),
                  _ToolCard(
                    title: 'Recurring',
                    icon: Icons.repeat_rounded,
                    color: Colors.purpleAccent,
                    onTap: () => context.push('/recurring-bills'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Recent Transactions Header ─────────────────────────────────
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8, top: 4),
              child: _SectionHeader(
                title: 'Recent Transactions',
                actionLabel: 'See All',
                onAction: () => context.push('/all-transactions'),
              ),
            ),

            // ── Transaction List ───────────────────────────────────────────
            Expanded(
              child: ClipRect(
                child: BlocBuilder<TransactionCubit, TransactionState>(
                  builder: (context, txState) {
                  if (txState is TransactionLoading) {
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
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
                          physics: const BouncingScrollPhysics(),
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
            ),
            ),
          ],
        ),
      ),
      ),
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
    return Container(
      width: 105,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // Very soft shadow instead of glow
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Subtle white circle behind icon
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title, 
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
        if (onAction != null && actionLabel.isNotEmpty)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
