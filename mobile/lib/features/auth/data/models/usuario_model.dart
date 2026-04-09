import '../../domain/entities/usuario_entity.dart';

class UsuarioModel extends UsuarioEntity {
  const UsuarioModel({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.usuario,
    required super.correo,
    super.telefono,
    super.url,
    required super.estado,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) => UsuarioModel(
        id: json['id'],
        nombre: json['nombre'],
        apellido: json['apellido'],
        usuario: json['usuario'],
        correo: json['correo'],
        telefono: json['telefono'],
        url: json['url'],
        estado: json['estado'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'usuario': usuario,
        'correo': correo,
        'telefono': telefono,
        'url': url,
        'estado': estado,
      };
}