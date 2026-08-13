import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../features/expenses/domain/entities/account.dart';
import '../../../../features/expenses/presentation/bloc/account_cubit.dart';

class AddAccountPage extends StatefulWidget {
  final AccountEntity? account;

  const AddAccountPage({
    super.key,
    this.account,
  });

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitController = TextEditingController();
  AccountType _selectedType = AccountType.asset;

  static const List<Color> _availableColors = [
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF2196F3), // Blue
    Color(0xFFE91E63), // Pink
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF00BCD4), // Cyan
  ];
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _limitController.text = widget.account!.creditLimit.toString();
      _selectedType = widget.account!.type;
      
      final colorIndex = _availableColors.indexWhere((c) => c.value == widget.account!.colorValue);
      if (colorIndex != -1) {
        _selectedColorIndex = colorIndex;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final balanceStr = _balanceController.text.trim();
    final limitStr = _limitController.text.trim();
    if (name.isEmpty || balanceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out the name and balance.')),
      );
      return;
    }

    final balance = double.tryParse(balanceStr) ?? 0.0;
    final limit = double.tryParse(limitStr) ?? 0.0;

    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    final userId = authState is AuthAuthenticated ? authState.user.id : '';
    
    final newAccount = AccountEntity(
      id: widget.account?.id ?? '',
      name: name,
      balance: balance,
      creditLimit: _selectedType == AccountType.liability ? limit : 0.0,
      type: _selectedType,
      userId: userId,
      colorValue: _availableColors[_selectedColorIndex].value,
    );

    if (widget.account != null) {
      context.read<AccountCubit>().updateAccount(newAccount);
    } else {
      context.read<AccountCubit>().addAccount(newAccount);
    }
    context.pop();
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSegmentTab(AccountType.asset, 'Asset (Cash, Bank)', Icons.account_balance_wallet_rounded),
          _buildSegmentTab(AccountType.liability, 'Liability (Credit)', Icons.credit_card_rounded),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(AccountType type, String title, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(4),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? Colors.white : Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.account != null ? 'Edit Account' : 'Add Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _submit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Type',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildSegmentedControl(),
            const SizedBox(height: 24),
            Text('Details',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildGlassContainer(
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Account Name (e.g. BOC)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.account_balance, color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildGlassContainer(
              child: TextField(
                controller: _balanceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Initial Balance',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            if (_selectedType == AccountType.liability) ...[
              const SizedBox(height: 12),
              _buildGlassContainer(
                child: TextField(
                  controller: _limitController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Credit Limit (Optional)',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.credit_score, color: Colors.white70),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Card Color',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildGlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_availableColors.length, (index) {
                    final color = _availableColors[index];
                    final isSelected = _selectedColorIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                          ],
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
