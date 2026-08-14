import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/account.dart';
import '../../../expenses/presentation/bloc/account_cubit.dart';
import '../../../expenses/presentation/bloc/account_state.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Accounts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            onPressed: () => _showAddEditAccountDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          if (state is AccountLoading || state is AccountInitial) {
            return const ShimmerTile();
          }
          if (state is AccountError) {
            return Center(child: Text(state.message, style: TextStyle(color: theme.colorScheme.error)));
          }

          if (state is AccountLoaded) {
            final accounts = state.accounts;

            if (accounts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No accounts found.', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Create your first account to start tracking.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showAddEditAccountDialog(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Account'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF50C8C8),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return _AccountListTile(account: account);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddEditAccountDialog(BuildContext context, [AccountEntity? account]) {
    context.push('/accounts/add-account', extra: account);
  }
}

class _AccountListTile extends StatelessWidget {
  final AccountEntity account;

  const _AccountListTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = account.type == AccountType.asset
        ? Icons.account_balance_wallet_rounded
        : Icons.credit_card_rounded;

    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text('Are you sure you want to delete this account?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<AccountCubit>().deleteAccount(account.id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: account.type == AccountType.asset
                    ? AppTheme.incomeColor.withValues(alpha: 0.1)
                    : theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.poppins(
                      textStyle: theme.textTheme.titleMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    account.type == AccountType.asset ? 'Asset' : 'Liability',
                    style: GoogleFonts.poppins(
                      textStyle: theme.textTheme.bodySmall,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (account.type == AccountType.liability) ...[
                  Text(
                    AppFormatters.formatCurrency(context, account.creditLimit - account.balance),
                    style: GoogleFonts.poppins(
                      textStyle: theme.textTheme.titleMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(context, account.balance),
                    style: GoogleFonts.poppins(
                      textStyle: theme.textTheme.bodySmall,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Text(
                    AppFormatters.formatCurrency(context, account.balance),
                    style: GoogleFonts.poppins(
                      textStyle: theme.textTheme.titleMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.edit_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
              onPressed: () {
                context.push('/accounts/add-account', extra: account);
              },
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }
}

