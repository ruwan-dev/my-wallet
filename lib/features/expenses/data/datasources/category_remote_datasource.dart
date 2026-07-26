import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDatasource {
  Future<List<CategoryModel>> getAllCategories(String userId);
  Future<void> saveCategory(String userId, CategoryModel category);
  Future<void> deleteCategory(String userId, String categoryId);
}

class FirestoreCategoryRemoteDatasource implements CategoryRemoteDatasource {
  final FirebaseFirestore firestore;

  FirestoreCategoryRemoteDatasource(this.firestore);

  @override
  Future<List<CategoryModel>> getAllCategories(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to fetch remote categories: $e');
    }
  }

  @override
  Future<void> saveCategory(String userId, CategoryModel category) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(category.id)
          .set(category.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw CacheException(message: 'Failed to save remote category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId)
          .delete();
    } catch (e) {
      throw CacheException(message: 'Failed to delete remote category: $e');
    }
  }
}
