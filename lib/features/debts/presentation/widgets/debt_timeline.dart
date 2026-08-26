import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/debt.dart';
import '../bloc/debt_cubit.dart';
import 'debt_card.dart';
import 'inline_debt_editor.dart';
import 'inline_payment_editor.dart';

class DebtTimeline extends StatefulWidget {
  final List<Debt> debts;
  final double fireBalance;

  const DebtTimeline({
    super.key,
    required this.debts,
    required this.fireBalance,
  });

  @override
  State<DebtTimeline> createState() => _DebtTimelineState();
}

class _DebtTimelineState extends State<DebtTimeline> {
  String? _payingDebtId;
  String? _editingDebtId;

  @override
  Widget build(BuildContext context) {
    if (widget.debts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'No active debts! You are doing great.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final sortedDebts = List<Debt>.from(widget.debts)
      ..sort((a, b) => a.currentBalance.compareTo(b.currentBalance));

    double maxDebt = 0;
    if (sortedDebts.isNotEmpty) {
      maxDebt = sortedDebts.map((d) => d.currentBalance).reduce((a, b) => a > b ? a : b);
    }

    return ListView.builder(
      shrinkWrap: true, // Allow it to take only necessary space vertically
      physics:
          const NeverScrollableScrollPhysics(), // Since it's inside a SingleChildScrollView already
      reverse: true, // Builds from bottom to top
      itemCount: sortedDebts.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return _buildTimelineNode(
            context, index, sortedDebts, maxDebt, widget.fireBalance);
      },
    );
  }

  Widget _buildTimelineNode(BuildContext context, int index,
      List<Debt> sortedDebts, double maxDebt, double currentFireBalance) {
    final debt = sortedDebts[index];
    final isCompleted = debt.currentBalance <= 0;
    final isTarget = !isCompleted &&
        (index == 0 ||
            sortedDebts.take(index).every((d) => d.currentBalance <= 0));

    final bool isFirst = index == 0;
    final bool isLast = index == sortedDebts.length - 1;

    Color calculateNodeColor(Debt d) {
      if (maxDebt <= 0) return const Color(0xFF80DEEA); // lightCyan
      double ratio = (d.currentBalance / maxDebt).clamp(0.0, 1.0);
      return Color.lerp(
        const Color(0xFF80DEEA), // 0%
        const Color(0xFF0097A7), // 100%
        ratio,
      )!;
    }

    Color colorMe = calculateNodeColor(debt);
    Color colorAbove = index < sortedDebts.length - 1
        ? calculateNodeColor(sortedDebts[index + 1])
        : colorMe;
    Color colorBelow = index > 0
        ? calculateNodeColor(sortedDebts[index - 1])
        : colorMe;

    double ratio = maxDebt > 0 ? (debt.currentBalance / maxDebt).clamp(0.0, 1.0) : 0.0;
    double nodeSize = 16.0;
    Color nodeColor = colorMe;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Main Content (Debt Card) - Dictates the height of the Stack
        Padding(
          padding: const EdgeInsets.only(left: 56.0, top: 8.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DebtCard(
                debt: debt,
                isTarget: isTarget,
                onPayTap: () {
                  if (currentFireBalance <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot pay: Fire Wallet balance is zero or negative.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                        useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: InlinePaymentEditor(
                        debt: debt,
                        currentFireBalance: currentFireBalance,
                        onCancel: () => Navigator.pop(context),
                        onSave: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                onEditTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                        useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: InlineDebtEditor(
                        initialDebt: debt,
                        onCancel: () => Navigator.pop(context),
                        onSave: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                onDeleteTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: AlertDialog(
                          backgroundColor: const Color(0xFF0F172A).withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                          ),
                          title: const Text('Delete Goal', style: TextStyle(color: Colors.white)),
                          content: Text('Are you sure you want to delete ${debt.name}? This action cannot be undone.', style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                context.read<DebtCubit>().deleteDebt(debt.id);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                onCompleteTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: AlertDialog(
                          backgroundColor: const Color(0xFF0F172A).withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                          ),
                          title: const Text('Mark as Completed', style: TextStyle(color: Colors.white)),
                          content: Text('Are you sure you want to mark ${debt.name} as completed? This will set its remaining balance to 0 without deducting from your Fire Wallet.', style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                context.read<DebtCubit>().editDebt(
                                      debtId: debt.id,
                                      name: debt.name,
                                      totalAmount: debt.totalAmount,
                                      currentBalance: 0,
                                    );
                              },
                              child: const Text('Complete', style: TextStyle(color: Colors.greenAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // 2. The Vertical Grow Line & Node
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dynamic colored line
              Positioned.fill(
                child: Column(
                  children: [
                    // Top Half
                    Expanded(
                      child: Container(
                        width: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              colorMe,
                              Color.lerp(colorMe, colorAbove, 0.5)!,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom Half
                    Expanded(
                      child: Container(
                        width: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(colorMe, colorBelow, 0.5)!,
                              colorMe,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // The Node / Checkpoint
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.circle,
                    color: nodeColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
