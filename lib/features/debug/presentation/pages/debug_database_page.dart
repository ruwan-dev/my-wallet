import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../expenses/data/models/account_model.dart';
import '../../../expenses/data/models/transaction_model.dart';

class DebugDatabasePage extends StatefulWidget {
  const DebugDatabasePage({super.key});

  @override
  State<DebugDatabasePage> createState() => _DebugDatabasePageState();
}

class _DebugDatabasePageState extends State<DebugDatabasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Box<AccountModel>     get _accountsBox     => Hive.box<AccountModel>(AppConstants.accountsBox);
  Box<TransactionModel> get _transactionsBox => Hive.box<TransactionModel>(AppConstants.transactionsBox);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete ALL accounts and transactions from Hive. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _accountsBox.clear();
      await _transactionsBox.clear();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ All Hive data cleared')),
        );
      }
    }
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 Data Inspector'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Accounts (${_accountsBox.length})'),
            Tab(text: 'Transactions (${_transactionsBox.length})'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AccountsTab(box: _accountsBox, fmt: _fmt, onRefresh: () => setState(() {})),
          _TransactionsTab(box: _transactionsBox, fmt: _fmt, onRefresh: () => setState(() {})),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_sweep_rounded),
            label: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _confirmAndClearAll,
          ),
        ),
      ),
    );
  }
}

// ── Accounts Tab ─────────────────────────────────────────────────────────────

class _AccountsTab extends StatelessWidget {
  final Box<AccountModel> box;
  final String Function(DateTime) fmt;
  final VoidCallback onRefresh;

  const _AccountsTab({required this.box, required this.fmt, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final accounts = box.values.toList();

    if (accounts.isEmpty) {
      return const _EmptyDebugState(label: 'No accounts in Hive box');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = accounts[i];
        final typeStr = a.typeIndex == 0 ? 'asset' : 'liability';
        return _DebugCard(
          icon: a.typeIndex == 0
              ? Icons.account_balance_wallet_rounded
              : Icons.credit_card_rounded,
          iconColor: a.typeIndex == 0 ? Colors.teal : Colors.orange,
          title: a.name,
          badge: typeStr,
          rows: [
            _Row('id',       a.id),
            _Row('name',     a.name),
            _Row('balance',  a.balance.toStringAsFixed(4)),
            _Row('typeIndex', '${a.typeIndex}  ($typeStr)'),
            _Row('userId',   a.userId),
          ],
        );
      },
    );
  }
}

// ── Transactions Tab ─────────────────────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  final Box<TransactionModel> box;
  final String Function(DateTime) fmt;
  final VoidCallback onRefresh;

  const _TransactionsTab({required this.box, required this.fmt, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final txs = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (txs.isEmpty) {
      return const _EmptyDebugState(label: 'No transactions in Hive box');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: txs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = txs[i];
        return _DebugCard(
          icon: t.isIncome
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          iconColor: t.isIncome ? Colors.green : Colors.red,
          title: t.title,
          badge: t.isIncome ? 'INCOME' : 'EXPENSE',
          rows: [
            _Row('id',           t.id),
            _Row('accountId',    t.accountId),
            _Row('userId',       t.userId),
            _Row('title',        t.title),
            _Row('amount',       t.amount.toStringAsFixed(4)),
            _Row('isIncome',     '${t.isIncome}'),
            _Row('categoryId',   t.categoryId),
            _Row('categoryName', t.categoryName),
            _Row('date',         fmt(t.date)),
            _Row('note',         t.note ?? '—'),
            _Row('createdAt',    fmt(t.createdAt)),
            _Row('updatedAt',    fmt(t.updatedAt)),
          ],
        );
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Row {
  final String key;
  final String value;
  const _Row(this.key, this.value);
}

class _DebugCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String badge;
  final List<_Row> rows;

  const _DebugCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.rows,
  });

  @override
  State<_DebugCard> createState() => _DebugCardState();
}

class _DebugCardState extends State<_DebugCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          // Header row — always visible
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded fields
          if (_expanded) ...[
            Divider(height: 1, color: theme.colorScheme.outline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: widget.rows.map((row) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            row.key,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDebugState extends StatelessWidget {
  final String label;
  const _EmptyDebugState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📭', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
        ],
      ),
    );
  }
}
