import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/account.dart';
import '../../../expenses/presentation/bloc/account_cubit.dart';
import '../../../expenses/presentation/bloc/account_state.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import '../../../expenses/presentation/widgets/credit_card_tile.dart';
import '../../../../core/bloc/settings_cubit.dart';
import '../../../../core/bloc/settings_state.dart';

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

            // Reverse the bucketAccountLinks map: accountId → bucketDisplayName
            return BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settings) {
                // Build a reverse lookup: accountId → bucket display name
                final Map<String, String> accountToBucket = {};
                settings.bucketAccountLinks.forEach((bucketKey, accountId) {
                  // Capitalise the bucket key nicely
                  accountToBucket[accountId] =
                      bucketKey[0].toUpperCase() + bucketKey.substring(1);
                });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Dismissible(
                      key: ValueKey(account.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 28),
                        child: Icon(Icons.delete_outline_rounded,
                            color: theme.colorScheme.error, size: 28),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.4),
                          builder: (ctx) => BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: AlertDialog(
                              backgroundColor:
                                  const Color(0xFF1E3A3A).withOpacity(0.85),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.5),
                              ),
                              title: const Text('Delete Account',
                                  style: TextStyle(color: Colors.white)),
                              content: const Text(
                                  'Are you sure you want to delete this account?',
                                  style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white60)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Delete',
                                      style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ) ??
                            false;
                      },
                      onDismissed: (_) {
                        context
                            .read<AccountCubit>()
                            .deleteAccount(account.id);
                      },
                      child: CreditCardTile(
                        account: account,
                        linkedBucketName: accountToBucket[account.id],
                        onTap: () => context
                            .push('/account-transactions', extra: account),
                        onEdit: () => context
                            .push('/accounts/add-account', extra: account),
                      ),
                    );
                  },
                );
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



