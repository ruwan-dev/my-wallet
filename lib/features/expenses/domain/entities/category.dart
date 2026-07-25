import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Domain entity representing an expense category.
class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final bool isDefault;
  final bool isIncome;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isIncome = false,
  });

  @override
  List<Object?> get props => [id, name, icon, color, isDefault, isIncome];
}

/// Pre-defined default categories shipped with the app.
class DefaultCategories {
  static const List<Map<String, dynamic>> raw = [
    {'id': 'food',          'name': 'Food & Dining',     'icon': '🍔', 'color': 0xFFFF6584, 'isIncome': false},
    {'id': 'transport',     'name': 'Transport',          'icon': '🚗', 'color': 0xFF42A5F5, 'isIncome': false},
    {'id': 'shopping',      'name': 'Shopping',           'icon': '🛍️', 'color': 0xFF6C63FF, 'isIncome': false},
    {'id': 'entertainment', 'name': 'Entertainment',      'icon': '🎬', 'color': 0xFFFFBE0B, 'isIncome': false},
    {'id': 'health',        'name': 'Health',             'icon': '💊', 'color': 0xFF4CAF50, 'isIncome': false},
    {'id': 'bills',         'name': 'Bills & Utilities',  'icon': '💡', 'color': 0xFFFF9800, 'isIncome': false},
    {'id': 'education',     'name': 'Education',          'icon': '📚', 'color': 0xFF9C27B0, 'isIncome': false},
    {'id': 'salary',        'name': 'Salary',             'icon': '💰', 'color': 0xFF4CAF50, 'isIncome': true},
    {'id': 'freelance',     'name': 'Freelance',          'icon': '💻', 'color': 0xFF03DAC6, 'isIncome': true},
    {'id': 'other_exp',     'name': 'Other Expense',      'icon': '📦', 'color': 0xFF8888AA, 'isIncome': false},
    {'id': 'other_inc',     'name': 'Other Income',       'icon': '💸', 'color': 0xFF8888AA, 'isIncome': true},
  ];

  static List<Category> get all => raw
      .map(
        (e) => Category(
          id:        e['id'] as String,
          name:      e['name'] as String,
          icon:      e['icon'] as String,
          color:     Color(e['color'] as int),
          isDefault: true,
          isIncome:  e['isIncome'] as bool,
        ),
      )
      .toList();
}
