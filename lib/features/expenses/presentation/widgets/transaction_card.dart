import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_cubit.dart';
import 'package:go_router/go_router.dart';
import 'category_icon.dart';

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

    // Amount colour: Darker shades for better contrast on glassmorphic backgrounds
    final amountColor = isIncome ? const Color(0xFF166534) : const Color(0xFFB91C1C);

    final amountText =
        '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(context, transaction.amount)}';

    final cardContent = InkWell(
      onTap: () => context.push(
        '/add-transaction',
        extra: transaction,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F8F7), // Match background for neumorphism
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(4, 4),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(-4, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                  children: [
                    // ── Leading: circular icon bubble ──────────────────────────────
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: amountColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: CategoryIcon(
                        iconStr: category.icon,
                        size: 22,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ── Middle: amount + subtitle ───────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            amountText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.w700,
                            ),
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

                    // ── Trailing: title + account ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  transaction.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              transaction.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: transaction.isFavorite 
                                  ? const Color(0xFFE05263) // Match the soft crimson
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5), // Increased contrast
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
                ), // End Row
              ), // End Padding
          ), // End inner Container
        ), // End outer Container
      ); // End InkWell
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
