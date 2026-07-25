import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDatasource {
  Future<List<CategoryModel>> getAllCategories();
  Future<void> saveCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class HiveCategoryLocalDatasource implements CategoryLocalDatasource {
  final Box<CategoryModel> box;

  HiveCategoryLocalDatasource(this.box);

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      return box.values.toList();
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
