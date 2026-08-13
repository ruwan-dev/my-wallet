import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/debt.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 5)
class DebtModel extends Debt {
  @HiveField(0)
  @override
  final String id;
  
  @HiveField(1)
  @override
  final String userId;
  
  @HiveField(2)
  @override
  final String name;
  
  @HiveField(3)
  @override
  final double totalAmount;
  
  @HiveField(5)
  @override
  final double currentBalance;
  
  @HiveField(6)
  @override
  final DateTime createdAt;

  const DebtModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalAmount,
    required this.currentBalance,
    required this.createdAt,
  }) : super(
          id: id,
          userId: userId,
          name: name,
          totalAmount: totalAmount,
          currentBalance: currentBalance,
          createdAt: createdAt,
        );

  factory DebtModel.fromEntity(Debt entity) {
    return DebtModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      totalAmount: entity.totalAmount,
      currentBalance: entity.currentBalance,
      createdAt: entity.createdAt,
    );
  }

  factory DebtModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DebtModel(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'totalAmount': totalAmount,
      'currentBalance': currentBalance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  DebtModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? totalAmount,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
