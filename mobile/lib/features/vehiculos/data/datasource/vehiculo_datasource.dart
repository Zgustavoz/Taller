import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
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

  Future<VehiculoModel> subirFoto(int id, File foto) async {
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
    final res = await _dio.patch('/vehiculos/$id/foto', data: formData);
    return VehiculoModel.fromJson(res.data);
  }
}
