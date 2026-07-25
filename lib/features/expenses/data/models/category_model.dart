import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final bool isDefault;

  @HiveField(5)
  final bool isIncome;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.isDefault,
    required this.isIncome,
  });

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      colorValue: entity.color.value,
      isDefault: entity.isDefault,
      isIncome: entity.isIncome,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      icon: icon,
      color: Color(colorValue),
      isDefault: isDefault,
      isIncome: isIncome,
    );
  }
}
