import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepositoryImpl(this._firebaseAuth);

  @override
  Future<void> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  @override
  Future<void> register(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  @override
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }
}
