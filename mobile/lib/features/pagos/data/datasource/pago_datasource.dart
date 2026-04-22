import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/pago_model.dart';

class PagoDatasource {
  final Dio _dio = ApiClient.instance.client;

  // Crear PaymentIntent → devuelve client_secret
  Future<Map<String, dynamic>> crearPaymentIntent({
    required int incidenteId,
    required double montoTotal,
  }) async {
    final res = await _dio.post('/pagos/crear-intent', data: {
      'incidente_id': incidenteId,
      'monto_total': montoTotal,
    });
    return res.data as Map<String, dynamic>;
  }

  // Confirmar pago después del Payment Sheet
  Future<Map<String, dynamic>> confirmarPago({
    required int incidenteId,
    required String paymentIntentId,
    required double montoTotal,
  }) async {
    final res = await _dio.post('/pagos/confirmar', data: {
      'incidente_id': incidenteId,
      'payment_intent_id': paymentIntentId,
      'monto_total': montoTotal,
    });
    return res.data as Map<String, dynamic>;
  }

  // Consultar si ya existe pago
  Future<Map<String, dynamic>> obtenerPago(int incidenteId) async {
    final res = await _dio.get('/pagos/incidente/$incidenteId');
    return res.data as Map<String, dynamic>;
  }

  // Listar pagos del usuario
  Future<List<Map<String, dynamic>>> listarMisPagos() async {
    final res = await _dio.get('/pagos/mis-pagos');

    return List<Map<String, dynamic>>.from(res.data);
  }
}