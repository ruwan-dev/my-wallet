import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:ui';
import '../../domain/entities/debt.dart';
import '../../../../core/theme/app_theme.dart';

class DebtCard extends StatefulWidget {
  final Debt debt;
  final bool isTarget;
  final VoidCallback onPayTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onCompleteTap;

  const DebtCard({
    super.key,
    required this.debt,
    this.isTarget = false,
    required this.onPayTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onCompleteTap,
  });

  @override
  State<DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<DebtCard>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPaidOff = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant DebtCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debt.currentBalance > 0 && widget.debt.currentBalance <= 0) {
      _handlePaidOff();
    }
  }

  void _handlePaidOff() {
    setState(() {
      _isPaidOff = true;
    });
    _confettiController.play();
    _animationController.forward().then((_) {
      // Typically we might notify parent to remove, but Cubit will handle state update.
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.debt.totalAmount > 0
        ? (widget.debt.totalAmount - widget.debt.currentBalance) /
            widget.debt.totalAmount
        : 0.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  decoration: ShapeDecoration(
                    color: widget.debt.currentBalance <= 0
                        ? const Color(0xFFE0F7FA)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: widget.debt.currentBalance <= 0
                            ? const Color(0xFF80DEEA)
                            : Colors.grey.withOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.debt.currentBalance > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.debt.name,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz, color: Colors.black54, size: 20),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                switch (value) {
                                  case 'pay':
                                    widget.onPayTap();
                                    break;
                                  case 'edit':
                                    widget.onEditTap();
                                    break;
                                  case 'complete':
                                    widget.onCompleteTap();
                                    break;
                                  case 'delete':
                                    widget.onDeleteTap();
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'pay',
                                  child: Row(children: [Icon(Icons.payment_outlined, size: 18, color: Color(0xFF00ACC1)), SizedBox(width: 8), Text('Pay')]),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                                ),
                                const PopupMenuItem(
                                  value: 'complete',
                                  child: Row(children: [Icon(Icons.check_circle_outline, size: 18, color: Colors.green), SizedBox(width: 8), Text('Complete')]),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Need to be paid: Rs ${widget.debt.currentBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFF00ACC1).withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00ACC1)),
                            minHeight: 4,
                          ),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFF00ACC1), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hooray! You successfully completed ${widget.debt.name} amount of Rs ${widget.debt.totalAmount.toStringAsFixed(0)}!',
                                style: const TextStyle(
                                  color: Color(0xFF00838F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 28,
                              child: TextButton(
                                onPressed: widget.onDeleteTap,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0F7FA),
                                  foregroundColor: const Color(0xFF00ACC1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Delete',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFE0F7FA),
          foregroundColor: const Color(0xFF00ACC1),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

