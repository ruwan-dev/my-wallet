import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_cubit.dart';

class TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onDelete;
  final String accountName;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isIncome = transaction.isIncome;

    final category = DefaultCategories.all.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => DefaultCategories.all.last,
    );

    // Amount colour: green for income, red for expense
    final amountColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;

    final amountText =
        '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(transaction.amount)}';

    final cardContent = InkWell(
      onTap: () => context.push(
        '/edit-expense/${transaction.id}',
        extra: transaction,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // ── Leading: circular icon bubble ──────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),

              // ── Middle: title + subtitle ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      transaction.subCategory != null && transaction.subCategory!.isNotEmpty
                          ? '${transaction.categoryName} (${transaction.subCategory})  •  ${AppFormatters.formatRelativeDate(transaction.date)}'
                          : '${transaction.categoryName}  •  ${AppFormatters.formatRelativeDate(transaction.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Trailing: amount ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          accountName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        transaction.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: transaction.isFavorite 
                            ? Colors.redAccent 
                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                        size: 20,
                      ),
                      onPressed: () {
                        // ignore: invalid_use_of_visible_for_testing_member
                        context.read<TransactionCubit>().updateTransaction(
                              transaction,
                              transaction.copyWith(isFavorite: !transaction.isFavorite),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    if (onDelete == null) {
      return cardContent;
    }

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete!(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.expenseColor, size: 26),
      ),
      child: cardContent,
    );
  }
}
