import '../../domain/entities/account.dart';

class AccountModel {
  final String id;
  final String name;
  final double balance;
  final int typeIndex;
  final String userId;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.typeIndex,
    required this.userId,
  });

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      name: entity.name,
      balance: entity.balance,
      typeIndex: entity.type.index,
      userId: entity.userId,
    );
  }

  AccountEntity toEntity() {
    return AccountEntity(
      id: id,
      name: name,
      balance: balance,
      type: AccountType.values[typeIndex],
      userId: userId,
    );
  }

  factory AccountModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AccountModel(
      id: documentId,
      name: data['name'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      typeIndex: data['typeIndex'] ?? 0,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'balance': balance,
      'typeIndex': typeIndex,
      'userId': userId,
    };
  }
}
