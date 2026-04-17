import 'dart:io';

import '../datasource/auth_datasource.dart';
import '../models/usuario_model.dart';

class AuthRepository {
  final AuthDatasource _datasource = AuthDatasource();

  Future<UsuarioModel> login({
    required String usuario,
    required String password,
  }) => _datasource.login(usuario: usuario, password: password);

  Future<UsuarioModel> register({
    required String nombre,
    required String apellido,
    required String usuario,
    required String correo,
    required String password,
    String? telefono,
  }) => _datasource.register(
        nombre: nombre,
        apellido: apellido,
        usuario: usuario,
        correo: correo,
        password: password,
        telefono: telefono,
      );

  Future<void> logout() => _datasource.logout();

  Future<UsuarioModel> me() => _datasource.me();

  Future<UsuarioModel> subirFotoPerfil(int usuarioId, File foto) =>
      _datasource.subirFotoPerfil(usuarioId, foto);
}