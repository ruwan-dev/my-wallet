import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerTile extends StatelessWidget {
  const ShimmerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Derive shimmer colors from the theme — no hardcoded hex values.
    final baseColor      = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surfaceContainerLow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 10, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Amount placeholder
            Container(width: 60, height: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
