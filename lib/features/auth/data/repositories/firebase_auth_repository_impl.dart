import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepositoryImpl(this._firebaseAuth, this._firestore);

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return UserEntity(
          id: uid,
          email: email,
          isPremium: data['isPremium'] ?? false,
          isAdmin: data['isAdmin'] ?? false,
          forceSync: data['forceSync'] ?? false,
        );
      } else {
        // Prevent login if Firestore document was deleted
        await _firebaseAuth.signOut();
        throw Exception('User data not found in the database. Please register again.');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorCode(e.code));
    } catch (e) {
      if (e.toString().contains('User data not found')) rethrow;
      throw Exception('An unexpected error occurred during login.');
    }
  }

  @override
  Future<UserEntity> register(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = credential.user!.uid;
      final user = UserEntity(id: uid, email: email, isPremium: false, isAdmin: false, forceSync: false);
      
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'isPremium': false,
        'isAdmin': false,
        'forceSync': false,
      });
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorCode(e.code));
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
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
  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      try {
        // Force verification with Firebase servers to ensure the user wasn't manually deleted or disabled
        await firebaseUser.reload();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'user-disabled') {
          await _firebaseAuth.signOut();
          return null;
        }
      } catch (_) {
        // Ignore network errors so the app still works offline
      }

      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return UserEntity(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          isPremium: data['isPremium'] ?? false,
          isAdmin: data['isAdmin'] ?? firebaseUser.email == 'admin@admin.com',
          forceSync: data['forceSync'] ?? false,
        );
      }
      
      // If Firestore document doesn't exist (e.g. manually deleted), invalidate session
      await _firebaseAuth.signOut();
      return null;
    }
    return null;
  }

  @override
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorCode(e.code));
    } catch (e) {
      throw Exception('An unexpected error occurred while sending reset link.');
    }
  }

  String _mapAuthErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account was found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account is already registered with this email address.';
      case 'operation-not-allowed':
        return 'This authentication method is not enabled.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'A network error occurred. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An unexpected authentication error occurred.';
    }
  }
}
