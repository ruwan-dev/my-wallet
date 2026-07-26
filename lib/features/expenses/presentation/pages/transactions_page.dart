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

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

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
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, txState) {
          if (txState is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (txState is TransactionLoaded) {
            final transactions = txState.transactions;

            if (transactions.isEmpty) {
              return Center(
                child: Text(
                  'No transactions found.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
