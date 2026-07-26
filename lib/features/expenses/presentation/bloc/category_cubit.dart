import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository repository;
  final AuthRepository authRepository;
  
  StreamSubscription? _subscription;

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

  void loadCategories() {
    if (state is! CategoryLoaded) {
      emit(CategoryLoading());
    }
    
    _subscription?.cancel();
    
    try {
      _subscription = repository.watchCustomCategories(_currentUserId).listen(
        (customCategories) {
          final Map<String, Category> merged = {};
          for (final c in DefaultCategories.all) {
            merged[c.id] = c;
          }
          for (final c in customCategories) {
            merged[c.id] = c;
          }
          final allCategories = merged.values.toList();
          emit(CategoryLoaded(allCategories));
        },
        onError: (e) {
          emit(CategoryError(e.toString()));
        },
      );
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> addCustomCategory(Category category) async {
    try {
      if (state is CategoryLoaded) {
        final current = (state as CategoryLoaded).categories;
        emit(CategoryLoaded([...current, category]));
      }
      await repository.saveCategory(_currentUserId, category);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      if (state is CategoryLoaded) {
        final current = (state as CategoryLoaded).categories;
        final updatedList = current.map((c) => c.id == category.id ? category : c).toList();
        emit(CategoryLoaded(updatedList));
      }
      await repository.saveCategory(_currentUserId, category);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> deleteCustomCategory(String id) async {
    try {
      if (state is CategoryLoaded) {
        final current = (state as CategoryLoaded).categories;
        final updatedList = current.where((c) => c.id != id).toList();
        emit(CategoryLoaded(updatedList));
      }
      await repository.deleteCategory(_currentUserId, id);
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
