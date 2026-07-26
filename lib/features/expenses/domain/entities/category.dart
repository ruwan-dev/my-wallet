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
  final List<String> subcategories;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isIncome = false,
    this.subcategories = const [],
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    bool? isDefault,
    bool? isIncome,
    List<String>? subcategories,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isIncome: isIncome ?? this.isIncome,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, isDefault, isIncome, subcategories];
}

/// Pre-defined default categories shipped with the app.
class DefaultCategories {
  static const List<Map<String, dynamic>> raw = [
    {'id': 'food',          'name': 'Food & Dining',     'icon': '🍔', 'color': 0xFFFF6584, 'isIncome': false, 'subcategories': ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Groceries', 'Dining Out']},
    {'id': 'transport',     'name': 'Transport',          'icon': '🚗', 'color': 0xFF42A5F5, 'isIncome': false, 'subcategories': ['Bus', 'Train', 'Taxi', 'Fuel', 'Maintenance', 'Flight']},
    {'id': 'shopping',      'name': 'Shopping',           'icon': '🛍️', 'color': 0xFF6C63FF, 'isIncome': false, 'subcategories': ['Clothing', 'Electronics', 'Groceries', 'Gifts']},
    {'id': 'entertainment', 'name': 'Entertainment',      'icon': '🎬', 'color': 0xFFFFBE0B, 'isIncome': false, 'subcategories': ['Movies', 'Games', 'Subscriptions', 'Events']},
    {'id': 'health',        'name': 'Health',             'icon': '💊', 'color': 0xFF4CAF50, 'isIncome': false, 'subcategories': ['Doctor', 'Pharmacy', 'Fitness']},
    {'id': 'bills',         'name': 'Bills & Utilities',  'icon': '💡', 'color': 0xFFFF9800, 'isIncome': false, 'subcategories': ['Electricity', 'Water', 'Internet', 'Phone', 'Rent']},
    {'id': 'education',     'name': 'Education',          'icon': '📚', 'color': 0xFF9C27B0, 'isIncome': false, 'subcategories': ['Tuition', 'Books', 'Courses']},
    {'id': 'salary',        'name': 'Salary',             'icon': '💰', 'color': 0xFF4CAF50, 'isIncome': true,  'subcategories': ['Base Pay', 'Bonus']},
    {'id': 'freelance',     'name': 'Freelance',          'icon': '💻', 'color': 0xFF03DAC6, 'isIncome': true,  'subcategories': ['Projects', 'Consulting']},
    {'id': 'other_exp',     'name': 'Other Expense',      'icon': '📦', 'color': 0xFF8888AA, 'isIncome': false, 'subcategories': []},
    {'id': 'other_inc',     'name': 'Other Income',       'icon': '💸', 'color': 0xFF8888AA, 'isIncome': true,  'subcategories': []},
  ];

  static List<Category> get all => raw
      .map(
        (e) => Category(
          id:            e['id'] as String,
          name:          e['name'] as String,
          icon:          e['icon'] as String,
          color:         Color(e['color'] as int),
          isDefault:     true,
          isIncome:      e['isIncome'] as bool,
          subcategories: List<String>.from(e['subcategories'] as List? ?? []),
        ),
      )
      .toList();
}
