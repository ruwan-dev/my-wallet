import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 3;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      balance: fields[2] as double,
      creditLimit: fields[3] as double,
      typeIndex: fields[4] as int,
      userId: fields[5] as String,
      colorValue: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.creditLimit)
      ..writeByte(4)
      ..write(obj.typeIndex)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.colorValue);
  }
}
