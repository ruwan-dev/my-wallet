import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/custom_budget.dart';

class CustomBudgetModel extends CustomBudgetEntity {
  const CustomBudgetModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.totalBudgetLimit,
    required super.items,
    required super.createdAt,
    super.isCompleted,
  });

  factory CustomBudgetModel.fromEntity(CustomBudgetEntity entity) {
    return CustomBudgetModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      totalBudgetLimit: entity.totalBudgetLimit,
      items: entity.items,
      createdAt: entity.createdAt,
      isCompleted: entity.isCompleted,
    );
  }

  factory CustomBudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final itemsList = itemsData.map((item) {
      final map = item as Map<String, dynamic>;
      return BudgetChecklistItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        allocatedAmount: (map['allocatedAmount'] as num?)?.toDouble() ?? 0.0,
        isCompleted: map['isCompleted'] ?? false,
        categoryId: map['categoryId'] as String?,
        categoryIcon: map['categoryIcon'] as String?,
        subcategory: map['subcategory'] as String?,
      );
    }).toList();

    return CustomBudgetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      totalBudgetLimit: (data['totalBudgetLimit'] as num?)?.toDouble() ?? 0.0,
      items: itemsList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'totalBudgetLimit': totalBudgetLimit,
      'createdAt': Timestamp.fromDate(createdAt),
      'isCompleted': isCompleted,
      'items': items.map((i) => {
        'id': i.id,
        'title': i.title,
        'allocatedAmount': i.allocatedAmount,
        'isCompleted': i.isCompleted,
        'categoryId': i.categoryId,
        'categoryIcon': i.categoryIcon,
        'subcategory': i.subcategory,
      }).toList(),
    };
  }
}
