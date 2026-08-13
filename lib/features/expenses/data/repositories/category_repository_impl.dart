import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/category_remote_datasource.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDatasource localDatasource;
  final CategoryRemoteDatasource remoteDatasource;
  final AuthRepository authRepository;

  CategoryRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.authRepository,
  });

  Future<bool> _isPremium() async {
    final user = await authRepository.getCurrentUser();
    return user?.isPremium ?? false;
  }

  @override
  Future<List<Category>> getCustomCategories(String userId) async {
    try {
      final isPremium = await _isPremium();
      if (isPremium) {
        final remoteModels = await remoteDatasource.getAllCategories(userId);
        return remoteModels.map((e) => e.toEntity()).toList();
      } else {
        final localModels = await localDatasource.getAllCategories(userId);
        // Since local categories don't enforce userId in get all yet, filter them if needed or just return.
        return localModels.map((e) => e.toEntity()).toList();
      }
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<Category>> watchCustomCategories(String userId) async* {
    final isPremium = await _isPremium();
    if (isPremium) {
      yield* remoteDatasource.watchAllCategories(userId).map((models) {
        return models.map((e) => e.toEntity()).toList();
      });
    } else {
      // Assuming no watch stream for Hive categories yet, just return single future as stream
      yield* Stream.fromFuture(localDatasource.getAllCategories(userId))
          .map((localModels) => localModels.map((e) => e.toEntity()).toList());
    }
  }

  @override
  Future<void> saveCategory(String userId, Category category) async {
    final model = CategoryModel.fromEntity(category, userId: userId);
    final isPremium = await _isPremium();
    if (isPremium) {
      await remoteDatasource.saveCategory(userId, model);
    } else {
      await localDatasource.saveCategory(model);
    }
  }

  @override
  Future<void> deleteCategory(String userId, String id) async {
    final isPremium = await _isPremium();
    if (isPremium) {
      await remoteDatasource.deleteCategory(userId, id);
    } else {
      await localDatasource.deleteCategory(id);
    }
  }
}
