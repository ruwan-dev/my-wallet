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
import '../bloc/budget_cubit.dart';
import '../bloc/budget_state.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/shimmer_tile.dart';
import '../widgets/transaction_card.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/set_budget_bottom_sheet.dart';
import '../widgets/animated_dashboard_card.dart';
import '../widgets/mesh_account_card.dart';
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
        listenWhen: (previous, current) {
          return current is TransactionLoaded && 
                 current.deletedTransaction != null && 
                 (previous is! TransactionLoaded || previous.deletedTransaction != current.deletedTransaction);
        },
        listener: (context, state) {
          if (state is TransactionLoaded && state.deletedTransaction != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('Transaction deleted'),
                duration: Duration(seconds: 3),
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
                        if (a.type == AccountType.liability) {
                          totalBalance -= a.balance;
                        } else {
                          totalBalance += a.balance;
                        }
                      }
                    }
                    final txState = context.watch<TransactionCubit>().state;
                    if (txState is TransactionLoaded) {
                      for (final tx in txState.transactions) {
                        if (tx.isIncome) totalIncome  += tx.amount;
                        else            totalExpense += tx.amount;
                      }
                    }

                    return AnimatedDashboardCard(
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
                      height: 130,
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
                            return MeshAccountCard(account: state.accounts[i]);
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

            // ── Budgets Header ─────────────────────────────────────────────
            BlocBuilder<BudgetCubit, BudgetState>(
              builder: (context, budgetState) {
                if (budgetState is BudgetLoaded && budgetState.summaries.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SectionHeader(
                        title: 'Monthly Budgets',
                        actionLabel: 'See All',
                        onAction: () => context.push('/budgets'),
                      ),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Monthly Budgets',
                      actionLabel: '+ Add',
                      onAction: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SetBudgetBottomSheet(),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // ── Budgets List ───────────────────────────────────────────────
            BlocBuilder<BudgetCubit, BudgetState>(
              builder: (context, budgetState) {
                if (budgetState is BudgetLoaded && budgetState.summaries.isNotEmpty) {
                  final sortedSummaries = List.of(budgetState.summaries)
                    ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
                  final topSummaries = sortedSummaries.take(3).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return BudgetProgressCard(
                            summary: topSummaries[index],
                          );
                        },
                        childCount: topSummaries.length,
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
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
                  onAction: () => context.push('/all-transactions'),
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
                      final recentTransactions = txState.transactions.take(2).toList();
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            _buildGroupedItems(
                                recentTransactions, accounts, context),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),

            // ── Bottom Padding for FAB ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
      String accountName = accounts
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
