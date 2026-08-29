import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../widgets/transaction_card.dart';
import '../widgets/shimmer_tile.dart';

class BucketTransactionsPage extends StatelessWidget {
  final BucketType bucketType;

  const BucketTransactionsPage({super.key, required this.bucketType});

  String _getBucketName() {
    switch (bucketType) {
      case BucketType.dailyExpenses: return 'Blow (Daily Expenses)';
      case BucketType.splurge: return 'Splurge';
      case BucketType.smile: return 'Smile';
      case BucketType.fire: return 'Fire';
      case BucketType.mojo: return 'Mojo';
      case BucketType.grow: return 'Grow';
      case BucketType.none: return 'Uncategorized';
    }
  }

  BucketType _getBucketForTx(TransactionEntity tx, List<Category> categories) {
    if (tx.bucketType != null) return tx.bucketType!;
    final cat = categories.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => const Category(id: '', name: 'Unknown', icon: '', color: Colors.grey, isIncome: false, subcategories: []),
    );
    if (tx.subCategory != null && cat.subcategoryBuckets.containsKey(tx.subCategory)) {
      return cat.subcategoryBuckets[tx.subCategory]!;
    }
    return cat.bucketType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Assumes background is handled (e.g. glassmorphism)
      appBar: AppBar(
        title: Text('${_getBucketName()} Transactions', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, catState) {
          if (catState is! CategoryLoaded) return const ShimmerTile();

          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              if (txState is! TransactionLoaded) return const ShimmerTile();

              final transactions = txState.transactions.where((tx) {
                // Filter by bucket
                return _getBucketForTx(tx, catState.categories) == bucketType;
              }).toList();

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No transactions for this bucket', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                physics: const BouncingScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TransactionCard(
                      transaction: transactions[index],
                      accountName: transactions[index].accountId, // Or fetch actual account name
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
