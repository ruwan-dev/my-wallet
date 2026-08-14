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

  Widget _buildSegmentedControl() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSegmentTab(AccountType.asset, 'Asset', Icons.account_balance_wallet_rounded),
          _buildSegmentTab(AccountType.liability, 'Liability', Icons.credit_card_rounded),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? const Color(0xFF50C8C8) : Colors.grey.shade500),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF50C8C8) : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          floatingLabelStyle: const TextStyle(color: Color(0xFF50C8C8), fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF50C8C8), width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F7),
      appBar: AppBar(
        title: Text(
          widget.account != null ? 'Edit Account' : 'Add Account',
          style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Color(0xFF1A1A2E), size: 28),
            onPressed: _submit,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Type', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildSegmentedControl(),
            const SizedBox(height: 32),
            Text('Details', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _nameController,
              label: 'Account Name',
              hint: 'e.g. Bank of Ceylon',
              icon: Icons.account_balance_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            _buildInputField(
              controller: _balanceController,
              label: 'Initial Balance',
              hint: '0.00',
              icon: Icons.attach_money_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (_selectedType == AccountType.liability)
              _buildInputField(
                controller: _limitController,
                label: 'Credit Limit (Optional)',
                hint: '0.00',
                icon: Icons.credit_score_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            const SizedBox(height: 16),
            Text('Card Color', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(_availableColors.length, (index) {
                final color = _availableColors[index];
                final isSelected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
