import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository repository;

  CategoryCubit({required this.repository}) : super(CategoryInitial());

  Future<void> loadCategories() async {
    emit(CategoryLoading());
    try {
      final customCategories = await repository.getCustomCategories();
      final allCategories = [...DefaultCategories.all, ...customCategories];
      emit(CategoryLoaded(allCategories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> addCustomCategory(Category category) async {
    try {
      await repository.saveCategory(category);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> deleteCustomCategory(String id) async {
    try {
      await repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
