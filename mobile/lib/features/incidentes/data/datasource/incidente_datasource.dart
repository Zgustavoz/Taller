import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import '../../../../core/network/api_client.dart';
import '../models/incidente_model.dart';
import '../models/tipo_incidente_model.dart';
import '../models/multimedia_model.dart';
import '../models/taller_cercano_model.dart';

class IncidenteDatasource {
  final Dio _dio = ApiClient.instance.client;

  // ─── Tipos de incidente ────────────────────────────────────
  Future<List<TipoIncidenteModel>> listarTipos() async {
    final res = await _dio.get('/tipos-incidente/');
    return (res.data as List)
        .map((e) => TipoIncidenteModel.fromJson(e))
        .toList();
  }

  // ─── Crear incidente con archivos (multipart) ──────────────
  Future<IncidenteModel> crear({
    required double latitud,
    required double longitud,
    String? descripcion,
    String? textoDireccion,
    int? tipoIncidenteId,
    int? vehiculoId,
    int? nivelPrioridad,
    List<File> archivos = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'latitud': latitud,
        'longitud': longitud,
        if (descripcion != null) 'descripcion': descripcion,
        if (textoDireccion != null) 'texto_direccion': textoDireccion,
        if (tipoIncidenteId != null) 'tipo_incidente_id': tipoIncidenteId,
        if (vehiculoId != null) 'vehiculo_id': vehiculoId,
        if (nivelPrioridad != null) 'nivel_prioridad': nivelPrioridad,
      });

      // Adjuntar archivos
      for (final archivo in archivos) {
        String mime = lookupMimeType(archivo.path) ?? 'application/octet-stream';
    
        // Fix: m4a no siempre es reconocido por lookupMimeType
        final ext = archivo.path.split('.').last.toLowerCase();
        if (ext == 'm4a') mime = 'audio/m4a';
        if (ext == 'aac') mime = 'audio/aac';
        if (ext == 'mp3') mime = 'audio/mpeg';
        if (ext == 'wav') mime = 'audio/wav';
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
        '/incidentes/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60), // Gemini puede tardar
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return IncidenteModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Mis incidentes ────────────────────────────────────────
  Future<List<IncidenteModel>> misIncidentes() async {
    try {
      final res = await _dio.get('/incidentes/mis-incidentes');
      return (res.data as List)
          .map((e) => IncidenteModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Detalle completo ──────────────────────────────────────
  Future<IncidenteModel> obtener(int id) async {
    try {
      final res = await _dio.get('/incidentes/$id');
      return IncidenteModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Talleres cercanos al incidente ───────────────────────
  Future<List<TallerCercanoModel>> talleresCercanos(
      int incidenteId, double radioKm) async {
    try {
      final res = await _dio.get(
        '/incidentes/$incidenteId/talleres-cercanos',
        queryParameters: {'radio_km': radioKm},
      );
      final lista = res.data['talleres'] as List;
      return lista.map((t) => TallerCercanoModel.fromJson(t)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Subir más archivos ────────────────────────────────────
  Future<List<MultimediaModel>> subirArchivos(
      int incidenteId, List<File> archivos) async {
    try {
      final formData = FormData();
      for (final archivo in archivos) {
        final mime =
            lookupMimeType(archivo.path) ?? 'application/octet-stream';
        formData.files.add(MapEntry(
          'archivos',
          await MultipartFile.fromFile(
            archivo.path,
            filename: archivo.path.split('/').last,
            contentType: DioMediaType.parse(mime),
          ),
        ));
      }
      final res = await _dio.post(
        '/incidentes/$incidenteId/multimedia',
        data: formData,
      );
      return (res.data as List)
          .map((e) => MultimediaModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Eliminar multimedia ───────────────────────────────────
  Future<void> eliminarMultimedia(int multimediaId) async {
    await _dio.delete('/incidentes/multimedia/$multimediaId');
  }

  String _handleError(DioException e) {
    if (e.response?.data is Map &&
        e.response!.data.containsKey('detail')) {
      return e.response!.data['detail'].toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.connectionError:
        return 'Sin conexión al servidor';
      default:
        return 'Error inesperado: ${e.message}';
    }
  }
}