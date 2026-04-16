import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import '../../../../core/network/api_client.dart';
import '../models/incidente_model.dart';
import '../models/tipo_incidente_model.dart';
import '../models/multimedia_model.dart';

class IncidenteDatasource {
  final Dio _dio = ApiClient.instance.client;

  // ─── Tipos de incidente ────────────────────────────────────
  Future<List<TipoIncidenteModel>> listarTipos() async {
    final res = await _dio.get('/tipos-incidente/');
    return (res.data as List).map((e) => TipoIncidenteModel.fromJson(e)).toList();
  }

  // ─── Crear incidente ───────────────────────────────────────
  Future<IncidenteModel> crear({
    required double latitud,
    required double longitud,
    String? textoDireccion,
    String? descripcion,
    int? tipoIncidenteId,
    int? nivelPrioridad,
  }) async {
    final res = await _dio.post('/incidentes/', data: {
      'latitud': latitud,
      'longitud': longitud,
      if (textoDireccion != null) 'texto_direccion': textoDireccion,
      if (descripcion != null) 'descripcion': descripcion,
      if (tipoIncidenteId != null) 'tipo_incidente_id': tipoIncidenteId,
      if (nivelPrioridad != null) 'nivel_prioridad': nivelPrioridad,
    });
    return IncidenteModel.fromJson(res.data);
  }

  // ─── Mis incidentes ────────────────────────────────────────
  Future<List<IncidenteModel>> misIncidentes() async {
    final res = await _dio.get('/incidentes/mis-incidentes');
    return (res.data as List).map((e) => IncidenteModel.fromJson(e)).toList();
  }

  // ─── Detalle ───────────────────────────────────────────────
  Future<IncidenteModel> obtener(int id) async {
    final res = await _dio.get('/incidentes/$id');
    return IncidenteModel.fromJson(res.data);
  }

  // ─── Subir archivos multimedia ─────────────────────────────
  Future<List<MultimediaModel>> subirArchivos(
    int incidenteId,
    List<File> archivos,
  ) async {
    final formData = FormData();
    for (final archivo in archivos) {
      final mime = lookupMimeType(archivo.path) ?? 'application/octet-stream';
      final nombre = archivo.path.split('/').last;
      formData.files.add(MapEntry(
        'archivos',
        await MultipartFile.fromFile(
          archivo.path,
          filename: nombre,
          contentType: DioMediaType.parse(mime),
        ),
      ));
    }
    final res = await _dio.post(
      '/incidentes/$incidenteId/multimedia',
      data: formData,
    );
    return (res.data as List).map((e) => MultimediaModel.fromJson(e)).toList();
  }

  // ─── Listar multimedia ─────────────────────────────────────
  Future<List<MultimediaModel>> listarMultimedia(int incidenteId) async {
    final res = await _dio.get('/incidentes/$incidenteId/multimedia');
    return (res.data as List).map((e) => MultimediaModel.fromJson(e)).toList();
  }

  // ─── Eliminar multimedia ───────────────────────────────────
  Future<void> eliminarMultimedia(int multimediaId) async {
    await _dio.delete('/incidentes/multimedia/$multimediaId');
  }

  String _handleError(DioException e) {
    if (e.response?.data is Map && e.response!.data.containsKey('detail')) {
      return e.response!.data['detail'].toString();
    }
    return 'Error de conexión';
  }
}