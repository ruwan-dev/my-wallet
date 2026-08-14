import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  final FirebaseAuth firebaseAuth;
  StreamSubscription? _authSubscription;

  AuthCubit({
    required this.repository,
    required this.firebaseAuth,
  }) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          final userEntity = await repository.getCurrentUser();
          if (userEntity != null) {
            emit(AuthAuthenticated(userEntity));
          } else {
            emit(AuthUnauthenticated());
          }
        } catch (_) {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await repository.login(email, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(errorMsg));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await repository.register(email, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(errorMsg));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await repository.loginWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(errorMsg));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await repository.resetPassword(email);
      emit(AuthUnauthenticated()); // Back to unauthenticated state after sending
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(errorMsg));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await repository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(errorMsg));
      final user = await repository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
