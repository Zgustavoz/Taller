import 'dart:io';
import '../datasource/vehiculo_datasource.dart';
import '../models/vehiculo_model.dart';

class VehiculoRepository {
  final _ds = VehiculoDatasource();

  Future<List<VehiculoModel>> misVehiculos() => _ds.misVehiculos();
  Future<VehiculoModel> crear(Map<String, dynamic> data) => _ds.crear(data);
  Future<VehiculoModel> actualizar(int id, Map<String, dynamic> data) =>
      _ds.actualizar(id, data);
  Future<VehiculoModel> subirFoto(int id, File foto) => _ds.subirFoto(id, foto);
  Future<void> eliminar(int id) => _ds.eliminar(id);
}