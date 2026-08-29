
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Container(
          width: 300,
          color: Colors.grey[200],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRow('Fire', 'Rs 38,552.40', true),
              _buildRow('Splurge', '-Rs 8,267.00', false),
            ],
          ),
        ),
      ),
    ),
  ));
}

Widget _buildRow(String name, String amount, bool hasChange) {
  return Row(
    children: [
      SizedBox(width: 48, child: Text(name)),
      Expanded(
        child: Container(
          color: Colors.red.withOpacity(0.2),
          child: Text(
            amount,
            textAlign: TextAlign.end,
          ),
        ),
      ),
      SizedBox(width: 4),
      Container(
        color: Colors.blue.withOpacity(0.2),
        width: 44,
        child: hasChange ? Row(children: [Icon(Icons.arrow_upward, size: 9), Text('38.6k')]) : const SizedBox.shrink(),
      ),
    ],
  );
}
