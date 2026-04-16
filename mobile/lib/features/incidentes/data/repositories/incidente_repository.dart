import 'dart:io';
import '../datasource/incidente_datasource.dart';
import '../models/incidente_model.dart';
import '../models/tipo_incidente_model.dart';
import '../models/multimedia_model.dart';

class IncidenteRepository {
  final _ds = IncidenteDatasource();

  Future<List<TipoIncidenteModel>> listarTipos() => _ds.listarTipos();

  Future<IncidenteModel> crear({
    required double latitud,
    required double longitud,
    String? textoDireccion,
    String? descripcion,
    int? tipoIncidenteId,
    int? nivelPrioridad,
  }) => _ds.crear(
        latitud: latitud,
        longitud: longitud,
        textoDireccion: textoDireccion,
        descripcion: descripcion,
        tipoIncidenteId: tipoIncidenteId,
        nivelPrioridad: nivelPrioridad,
      );

  Future<List<IncidenteModel>> misIncidentes() => _ds.misIncidentes();
  Future<IncidenteModel> obtener(int id) => _ds.obtener(id);
  Future<List<MultimediaModel>> subirArchivos(int id, List<File> archivos) =>
      _ds.subirArchivos(id, archivos);
  Future<List<MultimediaModel>> listarMultimedia(int id) => _ds.listarMultimedia(id);
  Future<void> eliminarMultimedia(int id) => _ds.eliminarMultimedia(id);
}