import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/account.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../bloc/account_cubit.dart';
import '../bloc/account_state.dart';
import '../widgets/transaction_card.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('All Transactions', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              if (txState is! TransactionLoaded || txState.transactions.isEmpty) {
                return const SizedBox.shrink();
              }
              final uniqueCategories = txState.transactions.map((t) => t.categoryName).toSet().toList()..sort();
              
              return IconButton(
                icon: Icon(
                  _selectedCategoryFilter != null ? Icons.filter_alt : Icons.filter_alt_outlined, 
                  color: _selectedCategoryFilter != null ? const Color(0xFF38B2AC) : const Color(0xFF1E293B),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                        useRootNavigator: true,
                    builder: (ctx) {
                      return SafeArea(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3AAFA9).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                                    child: Text('Filter by Category', 
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                                  ListTile(
                                    title: Text('All Categories', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    trailing: _selectedCategoryFilter == null ? const Icon(Icons.check, color: Colors.white) : null,
                                    onTap: () {
                                      setState(() => _selectedCategoryFilter = null);
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                                  Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: uniqueCategories.length,
                                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                                      itemBuilder: (ctx, i) {
                                        final cat = uniqueCategories[i];
                                        final isSelected = _selectedCategoryFilter == cat;
                                        return ListTile(
                                          title: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                          trailing: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                                          onTap: () {
                                            setState(() => _selectedCategoryFilter = cat);
                                            Navigator.pop(ctx);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, txState) {
            if (txState is TransactionLoading) {
              return const ShimmerTile();
            }
            if (txState is TransactionLoaded) {
              var transactions = txState.transactions;
              if (_selectedCategoryFilter != null) {
                transactions = transactions.where((t) => t.categoryName == _selectedCategoryFilter).toList();
              }

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No transactions found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_selectedCategoryFilter != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedCategoryFilter = null),
                          child: Text('Clear Filter', style: TextStyle(color: theme.colorScheme.primary)),
                        ),
                    ],
                  ),
                );
              }

              return BlocBuilder<AccountCubit, AccountState>(
                builder: (context, accState) {
                  final accounts = accState is AccountLoaded ? accState.accounts : <AccountEntity>[];
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final accountName = tx.accountId == 'planned'
                          ? 'Planned'
                          : accounts
                              .where((a) => a.id == tx.accountId)
                              .firstOrNull
                              ?.name ??
                          'Unknown Account';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TransactionCard(
                          transaction: tx,
                          accountName: accountName,
                          onDelete: () {
                            context.read<TransactionCubit>().deleteTransaction(tx);
                          },
                        ),
                      );
                    },
                  );
                }
              );
            }
            return const SizedBox.shrink();
          },
        ),
    );
  }
}
