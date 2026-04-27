import 'dart:io';
import '../datasource/incidente_datasource.dart';
import '../models/incidente_model.dart';
import '../models/tipo_incidente_model.dart';
import '../models/multimedia_model.dart';
import '../models/taller_cercano_model.dart';

class IncidenteRepository {
  final _ds = IncidenteDatasource();

  Future<List<TipoIncidenteModel>> listarTipos() => _ds.listarTipos();

  Future<IncidenteModel> crear({
    required double latitud,
    required double longitud,
    String? descripcion,
    String? textoDireccion,
    int? tipoIncidenteId,
    int? vehiculoId,
    int? nivelPrioridad,
    List<File> archivos = const [],
  }) =>
      _ds.crear(
        latitud: latitud,
        longitud: longitud,
        descripcion: descripcion,
        textoDireccion: textoDireccion,
        tipoIncidenteId: tipoIncidenteId,
        vehiculoId: vehiculoId,
        nivelPrioridad: nivelPrioridad,
        archivos: archivos,
      );

  Future<List<IncidenteModel>> misIncidentes() => _ds.misIncidentes();
  Future<IncidenteModel> obtener(int id) => _ds.obtener(id);
  Future<List<TallerCercanoModel>> talleresCercanos(int id, double radio) =>
      _ds.talleresCercanos(id, radio);
  Future<List<MultimediaModel>> subirArchivos(int id, List<File> archivos) =>
      _ds.subirArchivos(id, archivos);
  Future<void> eliminarMultimedia(int id) => _ds.eliminarMultimedia(id);

  Future<void> cancelar(int id, {String? motivo}) =>
    _ds.cancelar(id, motivo: motivo);

  Future<Map<String, dynamic>> calificar(int id,
          {required int puntuacion, String? comentario}) =>
      _ds.calificar(id, puntuacion: puntuacion, comentario: comentario);
}