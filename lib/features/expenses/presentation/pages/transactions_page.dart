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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('All Transactions', style: theme.textTheme.titleMedium),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                  color: _selectedCategoryFilter != null ? theme.colorScheme.primary : null,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Filter by Category', style: theme.textTheme.titleMedium),
                            ),
                            ListTile(
                              title: const Text('All Categories'),
                              trailing: _selectedCategoryFilter == null ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                              onTap: () {
                                setState(() => _selectedCategoryFilter = null);
                                Navigator.pop(ctx);
                              },
                            ),
                            const Divider(height: 1),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: uniqueCategories.length,
                                itemBuilder: (ctx, i) {
                                  final cat = uniqueCategories[i];
                                  final isSelected = _selectedCategoryFilter == cat;
                                  return ListTile(
                                    title: Text(cat),
                                    trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
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
            return const Center(child: CircularProgressIndicator());
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
                        child: const Text('Clear Filter'),
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
                    final accountName = accounts
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
