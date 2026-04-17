import 'package:equatable/equatable.dart';
import '../../domain/entities/usuario_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String usuario;
  final String password;
  const AuthLoginRequested({required this.usuario, required this.password});
  @override
  List<Object?> get props => [usuario, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String nombre;
  final String apellido;
  final String usuario;
  final String correo;
  final String password;
  final String? telefono;
  const AuthRegisterRequested({
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.correo,
    required this.password,
    this.telefono,
  });
  @override
  List<Object?> get props => [nombre, apellido, usuario, correo, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthUsuarioActualizado extends AuthEvent {
  final UsuarioEntity usuario;

  const AuthUsuarioActualizado(this.usuario);

  @override
  List<Object?> get props => [usuario];
}