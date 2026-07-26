import '../../domain/entities/account.dart';

class AccountModel {
  final String id;
  final String name;
  final double balance;
  final double creditLimit;
  final int typeIndex;
  final String userId;
  final int colorValue;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.creditLimit,
    required this.typeIndex,
    required this.userId,
    required this.colorValue,
  });

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      name: entity.name,
      balance: entity.balance,
      creditLimit: entity.creditLimit,
      typeIndex: entity.type.index,
      userId: entity.userId,
      colorValue: entity.colorValue,
    );
  }

  AccountEntity toEntity() {
    return AccountEntity(
      id: id,
      name: name,
      balance: balance,
      creditLimit: creditLimit,
      type: AccountType.values[typeIndex],
      userId: userId,
      colorValue: colorValue,
    );
  }

  factory AccountModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AccountModel(
      id: documentId,
      name: data['name'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (data['creditLimit'] as num?)?.toDouble() ?? 0.0,
      typeIndex: data['typeIndex'] ?? 0,
      userId: data['userId'] ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFF1E88E5,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'balance': balance,
      'creditLimit': creditLimit,
      'typeIndex': typeIndex,
      'userId': userId,
      'colorValue': colorValue,
    };
  }
}
