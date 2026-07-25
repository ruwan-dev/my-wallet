import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final TransactionEntity? deletedTransaction;

  const TransactionLoaded({
    required this.transactions,
    this.deletedTransaction,
  });

  TransactionLoaded copyWith({
    List<TransactionEntity>? transactions,
    TransactionEntity? deletedTransaction,
    bool clearDeleted = false,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      deletedTransaction: clearDeleted ? null : (deletedTransaction ?? this.deletedTransaction),
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        deletedTransaction,
      ];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
