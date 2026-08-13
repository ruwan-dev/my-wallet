import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String iconStr;
  final double size;
  final Color? color;

  const CategoryIcon({
    super.key,
    required this.iconStr,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final codePoint = int.tryParse(iconStr);
    if (codePoint != null) {
      return Icon(
        IconData(codePoint, fontFamily: 'MaterialIcons'),
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      );
    }
    // Fallback for legacy emoji categories
    return Text(
      iconStr,
      style: TextStyle(fontSize: size),
    );
  }
}
