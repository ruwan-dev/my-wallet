import 'package:equatable/equatable.dart';
import '../../domain/entities/debt.dart';

abstract class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object> get props => [];
}

class DebtInitial extends DebtState {}

class DebtLoading extends DebtState {}

class DebtLoaded extends DebtState {
  final List<Debt> debts;

  const DebtLoaded(this.debts);

  @override
  List<Object> get props => [debts];
}

class DebtError extends DebtState {
  final String message;

  const DebtError(this.message);

  @override
  List<Object> get props => [message];
}
