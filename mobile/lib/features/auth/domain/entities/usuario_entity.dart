import 'package:equatable/equatable.dart';

class UsuarioEntity extends Equatable {
  final int id;
  final String nombre;
  final String apellido;
  final String usuario;
  final String correo;
  final String? telefono;
  final String? url;
  final bool estado;

  const UsuarioEntity({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.correo,
    this.telefono,
    this.url,
    required this.estado,
  });

  @override
  List<Object?> get props => [id, usuario, correo];
}