import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDatasource localDatasource;

  CategoryRepositoryImpl(this.localDatasource);

  @override
  Future<List<Category>> getCustomCategories() async {
    final models = await localDatasource.getAllCategories();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> saveCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);
    await localDatasource.saveCategory(model);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await localDatasource.deleteCategory(id);
  }
}
