import 'package:equatable/equatable.dart';
import '../../domain/entities/usuario_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UsuarioEntity usuario;
  const AuthAuthenticated(this.usuario);
  @override
  List<Object?> get props => [usuario];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String mensaje;
  const AuthError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

class AuthRegisterSuccess extends AuthState {}
