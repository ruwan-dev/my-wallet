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

  void _showTransactionDetails(BuildContext context, ThemeData theme, Color amountColor, String amountText, Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: CategoryIcon(
                      iconStr: category.icon,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(amountText, style: theme.textTheme.headlineMedium?.copyWith(color: amountColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(transaction.title, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailRow(context, 'Category', transaction.categoryName),
            if (transaction.subCategory != null && transaction.subCategory!.isNotEmpty)
              _buildDetailRow(context, 'Subcategory', transaction.subCategory!),
            _buildDetailRow(context, 'Date', AppFormatters.formatDate(transaction.date)),
            _buildDetailRow(context, 'Account', accountName),
            if (transaction.bucketType != null && transaction.bucketType != BucketType.none)
              _buildDetailRow(context, 'Bucket', transaction.bucketType!.displayName),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                  context.push('/add-transaction', extra: transaction); // Then push edit
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B2AC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 15,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

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
      onTap: () => _showTransactionDetails(context, theme, amountColor, amountText, category),
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
                    // ── Middle: amount + category ───────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            amountText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.categoryName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // ── Trailing: favorite button ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
