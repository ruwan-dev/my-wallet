import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDatasource {
  Future<List<CategoryModel>> getAllCategories(String userId);
  Future<void> saveCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class HiveCategoryLocalDatasource implements CategoryLocalDatasource {
  final Box<CategoryModel> box;

  HiveCategoryLocalDatasource(this.box);

  @override
  Future<List<CategoryModel>> getAllCategories(String userId) async {
    try {
      final categories = box.values.toList();
      
      // Automatic Migration: If a category has no userId (e.g. from an older version),
      // assign it to the current user to prevent data loss.
      for (var c in categories) {
        if (c.userId.isEmpty) {
          final updated = CategoryModel(
            id: c.id,
            name: c.name,
            icon: c.icon,
            colorValue: c.colorValue,
            isDefault: c.isDefault,
            isIncome: c.isIncome,
            subcategories: c.subcategories,
            recurringConfigs: c.recurringConfigs,
            bucketType: c.bucketType,
            subcategoryBuckets: c.subcategoryBuckets,
            userId: userId,
          );
          await box.put(c.id, updated);
        }
      }
      
      return box.values.where((c) => c.userId == userId).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to fetch categories: $e');
    }
  }

  @override
  Future<void> saveCategory(CategoryModel category) async {
    try {
      await box.put(category.id, category);
    } catch (e) {
      throw CacheException(message: 'Failed to save category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await box.delete(id);
    } catch (e) {
      throw CacheException(message: 'Failed to delete category: $e');
    }
  }
}
