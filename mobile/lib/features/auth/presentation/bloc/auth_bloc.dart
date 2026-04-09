import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository = AuthRepository();

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckRequested>(_onCheck);
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final usuario = await _repository.login(
        usuario: event.usuario,
        password: event.password,
      );
      emit(AuthAuthenticated(usuario));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.register(
        nombre: event.nombre,
        apellido: event.apellido,
        usuario: event.usuario,
        correo: event.correo,
        password: event.password,
        telefono: event.telefono,
      );
      emit(AuthRegisterSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    try {
      final usuario = await _repository.me();
      emit(AuthAuthenticated(usuario));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
}