import 'package:equatable/equatable.dart';

/// Domain entity for an authenticated user.
class AppUser extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, createdAt];
}
