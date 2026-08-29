import 'package:equatable/equatable.dart';

class Debt extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double totalAmount;
  final double currentBalance;
  final DateTime createdAt;
  final DateTime? dueDate;

  const Debt({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalAmount,
    required this.currentBalance,
    required this.createdAt,
    this.dueDate,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        totalAmount,
        currentBalance,
        createdAt,
        dueDate,
      ];
}
