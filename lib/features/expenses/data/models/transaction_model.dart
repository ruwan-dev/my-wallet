import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';

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
  final bool isFixedExpense;
  final BucketType? bucketType;

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
    this.isFixedExpense = false,
    this.bucketType,
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
      isFixedExpense: entity.isFixedExpense,
      bucketType: entity.bucketType,
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
      isFixedExpense: isFixedExpense,
      bucketType: bucketType,
    );
  }

  factory TransactionModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    BucketType? parsedBucketType;
    if (data['bucketType'] != null) {
      try {
        parsedBucketType = BucketType.values.firstWhere((e) => e.name == data['bucketType']);
      } catch (_) {}
    }

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
      isFixedExpense: data['isFixedExpense'] ?? false,
      bucketType: parsedBucketType,
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
      'isFixedExpense': isFixedExpense,
      if (bucketType != null) 'bucketType': bucketType!.name,
    };
  }
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 4;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    BucketType? bucketType;
    if (fields[18] != null) {
      final String btName = fields[18] as String;
      try {
        bucketType = BucketType.values.firstWhere((e) => e.name == btName);
      } catch (_) {}
    }

    return TransactionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      amount: fields[3] as double,
      categoryId: fields[4] as String,
      categoryName: fields[5] as String,
      subCategory: fields[6] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
      isIncome: fields[8] as bool,
      note: fields[9] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[10] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[11] as int),
      accountId: fields[12] as String,
      recurrenceFrequency: fields[13] as String?,
      nextDueDate: fields[14] != null ? DateTime.fromMillisecondsSinceEpoch(fields[14] as int) : null,
      transferAccountId: fields[15] as String?,
      isFavorite: fields[16] as bool,
      isFixedExpense: fields[17] as bool,
      bucketType: bucketType,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.categoryName)
      ..writeByte(6)
      ..write(obj.subCategory)
      ..writeByte(7)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.isIncome)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(11)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      ..writeByte(12)
      ..write(obj.accountId)
      ..writeByte(13)
      ..write(obj.recurrenceFrequency)
      ..writeByte(14)
      ..write(obj.nextDueDate?.millisecondsSinceEpoch)
      ..writeByte(15)
      ..write(obj.transferAccountId)
      ..writeByte(16)
      ..write(obj.isFavorite)
      ..writeByte(17)
      ..write(obj.isFixedExpense)
      ..writeByte(18)
      ..write(obj.bucketType?.name);
  }
}
