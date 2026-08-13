import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final bool isPremium;
  final bool isAdmin;
  final bool forceSync;

  const UserEntity({
    required this.id,
    required this.email,
    this.isPremium = false,
    this.isAdmin = false,
    this.forceSync = false,
  });

  @override
  List<Object?> get props => [id, email, isPremium, isAdmin, forceSync];
}
