import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDatasource localDatasource;
  final CategoryRemoteDatasource remoteDatasource;

  CategoryRepositoryImpl(this.localDatasource, this.remoteDatasource);

  @override
  Future<List<Category>> getCustomCategories(String userId) async {
    try {
      // 1. Fetch from remote
      final remoteModels = await remoteDatasource.getAllCategories(userId);
      // 2. Sync to local
      for (final model in remoteModels) {
        await localDatasource.saveCategory(model);
      }
      return remoteModels.map((e) => e.toEntity()).toList();
    } catch (_) {
      // Fallback to local if remote fails
      final localModels = await localDatasource.getAllCategories();
      return localModels.map((e) => e.toEntity()).toList();
    }
  }

  @override
  Stream<List<Category>> watchCustomCategories(String userId) {
    try {
      return remoteDatasource.watchAllCategories(userId).map((remoteModels) {
        // Sync to local silently
        for (final model in remoteModels) {
          localDatasource.saveCategory(model);
        }
        return remoteModels.map((e) => e.toEntity()).toList();
      });
    } catch (_) {
      // If stream creation fails entirely, return a fallback stream from local
      return Stream.fromFuture(localDatasource.getAllCategories())
          .map((localModels) => localModels.map((e) => e.toEntity()).toList());
    }
  }

  @override
  Future<void> saveCategory(String userId, Category category) async {
    final model = CategoryModel.fromEntity(category);
    // Save to local first for immediate feedback
    await localDatasource.saveCategory(model);
    
    // Sync to remote (swallow error if offline/failed to not break UI)
    try {
      await remoteDatasource.saveCategory(userId, model);
    } catch (e) {
      print('Warning: Failed to sync category to remote: $e');
    }
  }

  @override
  Future<void> deleteCategory(String userId, String id) async {
    await localDatasource.deleteCategory(id);
    try {
      await remoteDatasource.deleteCategory(userId, id);
    } catch (e) {
      print('Warning: Failed to delete category from remote: $e');
    }
  }
}
