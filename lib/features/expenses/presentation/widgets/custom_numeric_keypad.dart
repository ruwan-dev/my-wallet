import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNumericKeypad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspacePressed;

  const CustomNumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspacePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget buildKey(String label) {
      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onKeyPressed(label);
        },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    Widget buildActionKey(Widget icon, VoidCallback? onTap) {
      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Center(child: icon),
      );
    }

    Widget buildRow(List<Widget> children) {
      return Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children.map((c) => Expanded(child: c)).toList(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildRow([buildKey('1'), buildKey('2'), buildKey('3')]),
          const SizedBox(height: 8),
          buildRow([buildKey('4'), buildKey('5'), buildKey('6')]),
          const SizedBox(height: 8),
          buildRow([buildKey('7'), buildKey('8'), buildKey('9')]),
          const SizedBox(height: 8),
          buildRow([
            buildKey('.'),
            buildKey('0'),
            buildActionKey(
              Icon(Icons.backspace_outlined, color: theme.colorScheme.onSurface, size: 28),
              onBackspacePressed,
            ),
          ]),
        ],
      ),
    );
  }
}
