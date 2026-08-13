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
                        ? const Color(0xFF7C3AED).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: widget.debt.currentBalance <= 0
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
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
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Need to be paid: Rs ${widget.debt.currentBalance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C3AED)),
                            minHeight: 4,
                          ),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFD8B4E2), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hooray! You successfully completed ${widget.debt.name} amount of Rs ${widget.debt.totalAmount.toStringAsFixed(0)}!',
                                style: const TextStyle(
                                  color: Color(0xFFD8B4E2),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.5)),
                                  ),
                                ),
                                child: const Text('Delete',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.debt.currentBalance > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 28,
                              child: TextButton(
                                onPressed: widget.onDeleteTap,
                                child: const Text('Delete',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 28,
                              child: TextButton(
                                onPressed: widget.onEditTap,
                                child: const Text('Edit',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 28,
                              child: TextButton(
                                onPressed: widget.onCompleteTap,
                                child: const Text('Complete',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 28,
                              child: TextButton(
                                onPressed: widget.onPayTap,
                                child: const Text('Pay',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
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
}

