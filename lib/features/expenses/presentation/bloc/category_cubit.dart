import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository repository;
  final AuthRepository authRepository;

  CategoryCubit({
    required this.repository,
    required this.authRepository,
  }) : super(CategoryInitial());

  String get _currentUserId {
    final uid = authRepository.getCurrentUserId();
    if (uid == null || uid.isEmpty) {
      throw Exception('Unauthenticated: Cannot access categories.');
    }
    return uid;
  }

  Future<void> loadCategories() async {
    if (state is! CategoryLoaded) {
      emit(CategoryLoading());
    }
    try {
      final customCategories = await repository.getCustomCategories(_currentUserId);
      final Map<String, Category> merged = {};
      for (final c in DefaultCategories.all) {
        merged[c.id] = c;
      }
      for (final c in customCategories) {
        merged[c.id] = c;
      }
      final allCategories = merged.values.toList();
      emit(CategoryLoaded(allCategories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> addCustomCategory(Category category) async {
    try {
      await repository.saveCategory(_currentUserId, category);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await repository.saveCategory(_currentUserId, category);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> deleteCustomCategory(String id) async {
    try {
      await repository.deleteCategory(_currentUserId, id);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
