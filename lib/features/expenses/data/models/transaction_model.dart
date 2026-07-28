import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String? subCategory;
  final DateTime date;
  final bool isIncome;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String accountId;
  final String? recurrenceFrequency;
  final DateTime? nextDueDate;
  final String? transferAccountId;
  final bool isFavorite;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.subCategory,
    required this.date,
    required this.isIncome,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.accountId,
    this.recurrenceFrequency,
    this.nextDueDate,
    this.transferAccountId,
    this.isFavorite = false,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      amount: entity.amount,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      subCategory: entity.subCategory,
      date: entity.date,
      isIncome: entity.isIncome,
      note: entity.note,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      accountId: entity.accountId,
      recurrenceFrequency: entity.recurrenceFrequency,
      nextDueDate: entity.nextDueDate,
      transferAccountId: entity.transferAccountId,
      isFavorite: entity.isFavorite,
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
      subCategory: subCategory,
      date: date,
      isIncome: isIncome,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      accountId: accountId,
      recurrenceFrequency: recurrenceFrequency,
      nextDueDate: nextDueDate,
      transferAccountId: transferAccountId,
      isFavorite: isFavorite,
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
      subCategory: data['subCategory'],
      date: (data['date'] as Timestamp).toDate(),
      isIncome: data['isIncome'] ?? false,
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      accountId: data['accountId'] ?? '',
      recurrenceFrequency: data['recurrenceFrequency'],
      nextDueDate: data['nextDueDate'] != null ? (data['nextDueDate'] as Timestamp).toDate() : null,
      transferAccountId: data['transferAccountId'],
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      if (subCategory != null) 'subCategory': subCategory,
      'date': Timestamp.fromDate(date),
      'isIncome': isIncome,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'accountId': accountId,
      if (recurrenceFrequency != null) 'recurrenceFrequency': recurrenceFrequency,
      if (nextDueDate != null) 'nextDueDate': Timestamp.fromDate(nextDueDate!),
      if (transferAccountId != null) 'transferAccountId': transferAccountId,
      'isFavorite': isFavorite,
    };
  }
}
