import 'package:equatable/equatable.dart';

enum AccountType { asset, liability }

class AccountEntity extends Equatable {
  final String id;
  final String name;
  final double balance;
  final AccountType type;
  final String userId;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.userId,
  });

  AccountEntity copyWith({
    String? id,
    String? name,
    double? balance,
    AccountType? type,
    String? userId,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [id, name, balance, type, userId];
}
