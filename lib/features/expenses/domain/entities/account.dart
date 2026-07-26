import 'package:equatable/equatable.dart';

enum AccountType { asset, liability }

class AccountEntity extends Equatable {
  final String id;
  final String name;
  final double balance;
  final double creditLimit;
  final AccountType type;
  final String userId;
  final int colorValue;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.balance,
    this.creditLimit = 0.0,
    required this.type,
    required this.userId,
    this.colorValue = 0xFF1E88E5, // Default blue
  });

  AccountEntity copyWith({
    String? id,
    String? name,
    double? balance,
    double? creditLimit,
    AccountType? type,
    String? userId,
    int? colorValue,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  List<Object?> get props => [id, name, balance, creditLimit, type, userId, colorValue];
}
