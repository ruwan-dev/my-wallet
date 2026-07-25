import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final bool isIncome;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String accountId;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.isIncome,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.accountId,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      amount: entity.amount,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      date: entity.date,
      isIncome: entity.isIncome,
      note: entity.note,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      accountId: entity.accountId,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      title: title,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      date: date,
      isIncome: isIncome,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      accountId: accountId,
    );
  }

  factory TransactionModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return TransactionModel(
      id: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isIncome: data['isIncome'] ?? false,
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      accountId: data['accountId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': Timestamp.fromDate(date),
      'isIncome': isIncome,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'accountId': accountId,
    };
  }
}
