import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/notificacion_model.dart';

class NotificacionDatasource {
  final Dio _dio = ApiClient.instance.client;

  Future<List<NotificacionModel>> misNotificaciones(
      {bool soloNoLeidas = false}) async {
    final res = await _dio.get(
      '/notificaciones/mis-notificaciones',
      queryParameters: {'solo_no_leidas': soloNoLeidas},
    );
    return (res.data as List)
        .map((e) => NotificacionModel.fromJson(e))
        .toList();
  }

  Future<int> contarNoLeidas() async {
    final res = await _dio.get('/notificaciones/no-leidas');
    return res.data['total'] ?? 0;
  }

  Future<void> marcarLeida(int id) async {
    await _dio.patch('/notificaciones/$id/leer');
  }

  Future<void> marcarTodasLeidas() async {
    await _dio.patch('/notificaciones/todas/leer');
  }
}