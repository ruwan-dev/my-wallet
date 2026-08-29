import 'package:flutter/material.dart';
import '../../domain/entities/debt.dart';
import 'dart:ui';

class SmartSuggestionSheet extends StatelessWidget {
  final Debt debt;
  final double availableFireBalance;
  final VoidCallback onPayTap;

  const SmartSuggestionSheet({
    super.key,
    required this.debt,
    required this.availableFireBalance,
    required this.onPayTap,
  });

  static Future<void> show(
    BuildContext context, {
    required Debt debt,
    required double availableFireBalance,
    required VoidCallback onPayTap,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SmartSuggestionSheet(
        debt: debt,
        availableFireBalance: availableFireBalance,
        onPayTap: onPayTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(
              Icons.auto_awesome,
              color: Colors.amberAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Debt Destroyer Opportunity!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have Rs ${availableFireBalance.toStringAsFixed(0)} in your Heal Bucket.\n\nThis is enough to completely clear off your smallest debt: ${debt.name} (Rs ${debt.currentBalance.toStringAsFixed(0)}).',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Not Now',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onPayTap();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.redAccent.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
