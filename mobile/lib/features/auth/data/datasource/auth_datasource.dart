import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/usuario_model.dart';

class AuthDatasource {
  final Dio _dio = ApiClient.instance.client;

  // ─── Login ─────────────────────────────────────────────────
  Future<UsuarioModel> login({
    required String usuario,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'usuario': usuario, 'password': password},
      );
      return UsuarioModel.fromJson(response.data['usuario']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Register ───────────────────────────────────────────────
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

  // ─── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Me ─────────────────────────────────────────────────────
  Future<UsuarioModel> me() async {
    try {
      final response = await _dio.get('/auth/me');
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