import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String accountId;
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

  const TransactionEntity({
    required this.id,
    required this.accountId,
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
  });

  double get signedAmount => isIncome ? amount : -amount;

  TransactionEntity copyWith({
    String? id,
    String? accountId,
    String? userId,
    String? title,
    double? amount,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    bool? isIncome,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TransactionEntity(
        id:           id           ?? this.id,
        accountId:    accountId    ?? this.accountId,
        userId:       userId       ?? this.userId,
        title:        title        ?? this.title,
        amount:       amount       ?? this.amount,
        categoryId:   categoryId   ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        date:         date         ?? this.date,
        isIncome:     isIncome     ?? this.isIncome,
        note:         note         ?? this.note,
        createdAt:    createdAt    ?? this.createdAt,
        updatedAt:    updatedAt    ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id, accountId, userId, title, amount, categoryId,
        categoryName, date, isIncome, note, createdAt, updatedAt,
      ];
}
