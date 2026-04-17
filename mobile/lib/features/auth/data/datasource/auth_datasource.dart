import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/usuario_model.dart';

class AuthDatasource {
  final Dio _dio = ApiClient.instance.client;

  // ─── Guardar token ──────────────────────────────────────
  Future<void> _guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // ─── Limpiar token ──────────────────────────────────────
  Future<void> _limpiarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // ─── Login ─────────────────────────────────────────────
  Future<UsuarioModel> login({
    required String usuario,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'usuario': usuario, 'password': password},
      );
      // Guardar token en SharedPreferences
      final token = response.data['access_token'];
      if (token != null) await _guardarToken(token);

      return UsuarioModel.fromJson(response.data['usuario']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Register ───────────────────────────────────────────
  Future<UsuarioModel> register({
    required String nombre,
    required String apellido,
    required String usuario,
    required String correo,
    required String password,
    String? telefono,
  }) async {
    try {
      final response = await _dio.post(
        '/usuarios/',
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'usuario': usuario,
          'correo': correo,
          'password': password,
          if (telefono != null) 'telefono': telefono,
        },
      );
      return UsuarioModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Logout ─────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await _limpiarToken();   // siempre limpia local
    }
  }

  // ─── Me ─────────────────────────────────────────────────
  Future<UsuarioModel> me() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = response.data;
      final usuarioJson = data is Map && data.containsKey('usuario')
          ? data['usuario']
          : data;
      return UsuarioModel.fromJson(usuarioJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UsuarioModel> subirFotoPerfil(int usuarioId, File foto) async {
    try {
      final formData = FormData();
      final mime = lookupMimeType(foto.path) ?? 'application/octet-stream';
      final nombre = foto.path.split('/').last;
      formData.files.add(
        MapEntry(
          'foto',
          await MultipartFile.fromFile(
            foto.path,
            filename: nombre,
            contentType: DioMediaType.parse(mime),
          ),
        ),
      );
      final response = await _dio.patch('/usuarios/$usuarioId/foto', data: formData);
      return UsuarioModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.connectionError:
        return 'Sin conexión al servidor';
      default:
        return 'Error inesperado';
    }
  }
}