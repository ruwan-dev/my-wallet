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

  @HiveField(6)
  final List<String> subcategories;

  @HiveField(7)
  final Map<dynamic, dynamic>? recurringConfigs;

  @HiveField(8, defaultValue: 'none')
  final String bucketType;

  @HiveField(9, defaultValue: {})
  final Map<dynamic, dynamic>? subcategoryBuckets;

  @HiveField(10, defaultValue: '')
  final String userId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.isDefault,
    required this.isIncome,
    required this.subcategories,
    this.recurringConfigs,
    this.bucketType = 'none',
    this.subcategoryBuckets = const {},
    this.userId = '',
  });

  factory CategoryModel.fromEntity(Category entity, {String userId = ''}) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      colorValue: entity.color.value,
      isDefault: entity.isDefault,
      isIncome: entity.isIncome,
      subcategories: entity.subcategories,
      recurringConfigs: entity.recurringConfigs,
      bucketType: entity.bucketType.name,
      subcategoryBuckets: entity.subcategoryBuckets.map((key, value) => MapEntry(key, value.name)),
      userId: userId,
    );
  }

  BucketType _mapBucketType(String bt) {
    if (bt == 'blow') return BucketType.dailyExpenses;
    if (bt == 'splurge') return BucketType.enjoy;
    if (bt == 'grow') return BucketType.grow;
    return BucketType.values.firstWhere((e) => e.name == bt, orElse: () => BucketType.none);
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      icon: icon,
      color: Color(colorValue),
      isDefault: isDefault,
      isIncome: isIncome,
      subcategories: subcategories,
      recurringConfigs: recurringConfigs?.map((key, value) => MapEntry(key.toString(), value)) ?? const {},
      bucketType: _mapBucketType(bucketType),
      subcategoryBuckets: subcategoryBuckets?.map((key, value) => MapEntry(
        key.toString(), 
        _mapBucketType(value.toString())
      )) ?? const {},
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      colorValue: json['colorValue'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
      isIncome: json['isIncome'] as bool? ?? false,
      subcategories: List<String>.from(json['subcategories'] as List? ?? []),
      recurringConfigs: json['recurringConfigs'] as Map<dynamic, dynamic>?,
      bucketType: json['bucketType'] as String? ?? 'none',
      subcategoryBuckets: json['subcategoryBuckets'] as Map<dynamic, dynamic>?,
      userId: json['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'isDefault': isDefault,
      'isIncome': isIncome,
      'subcategories': subcategories,
      'recurringConfigs': recurringConfigs,
      'bucketType': bucketType,
      'subcategoryBuckets': subcategoryBuckets,
      'userId': userId,
    };
  }
}
