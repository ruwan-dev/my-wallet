import '../../domain/entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCustomCategories(String userId);
  Stream<List<Category>> watchCustomCategories(String userId);
  Future<void> saveCategory(String userId, Category category);
  Future<void> deleteCategory(String userId, String id);
}
