import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/vehiculo_model.dart';

class VehiculoDatasource {
  final Dio _dio = ApiClient.instance.client;

  Future<List<VehiculoModel>> misVehiculos() async {
    final res = await _dio.get('/vehiculos/mis-vehiculos');
    return (res.data as List).map((e) => VehiculoModel.fromJson(e)).toList();
  }

  Future<VehiculoModel> crear(Map<String, dynamic> data) async {
    final res = await _dio.post('/vehiculos/', data: data);
    return VehiculoModel.fromJson(res.data);
  }

  Future<VehiculoModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/vehiculos/$id', data: data);
    return VehiculoModel.fromJson(res.data);
  }

  Future<void> eliminar(int id) async {
    await _dio.delete('/vehiculos/$id');
  }
}