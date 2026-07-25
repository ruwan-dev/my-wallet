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
    _authSubscription = firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user.uid));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await repository.login(email, password);
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register(String email, String password) async {
    emit(AuthLoading());
    try {
      await repository.register(email, password);
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await repository.logout();
    } catch (e) {
      emit(AuthError(e.toString()));
      if (firebaseAuth.currentUser != null) {
        emit(AuthAuthenticated(firebaseAuth.currentUser!.uid));
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
