import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/account.dart';
import '../../../expenses/presentation/bloc/account_cubit.dart';
import '../../../expenses/presentation/bloc/account_state.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Accounts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          if (state is AccountLoading || state is AccountInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AccountError) {
            return Center(child: Text(state.message, style: TextStyle(color: theme.colorScheme.error)));
          }

          if (state is AccountLoaded) {
            final accounts = state.accounts;

            if (accounts.isEmpty) {
              return const Center(
                child: Text('No accounts found. Add one to get started!'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        backgroundColor: AppTheme.incomeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AddAccountDialog(),
    );
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
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
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
                color: account.type == AccountType.asset ? AppTheme.incomeColor : theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    account.type == AccountType.asset ? 'Asset' : 'Liability',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              AppFormatters.formatCurrency(account.balance),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _selectedType = AccountType.asset;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final balanceStr = _balanceController.text.trim();
    if (name.isEmpty || balanceStr.isEmpty) return;

    final balance = double.tryParse(balanceStr) ?? 0.0;

    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    final userId = authState is AuthAuthenticated ? authState.userId : '';
    
    final newAccount = AccountEntity(
      id: '',
      name: name,
      balance: balance,
      type: _selectedType,
      userId: userId,
    );

    context.read<AccountCubit>().addAccount(newAccount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Account Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceController,
            decoration: const InputDecoration(labelText: 'Initial Balance'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccountType>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Account Type'),
            items: const [
              DropdownMenuItem(value: AccountType.asset, child: Text('Asset (Cash, Bank)')),
              DropdownMenuItem(value: AccountType.liability, child: Text('Liability (Credit Card)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit, // We will implement _submit later after adding method to AccountCubit
          child: const Text('Add'),
        ),
      ],
    );
  }
}
