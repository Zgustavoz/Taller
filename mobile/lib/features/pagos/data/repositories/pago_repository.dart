import '../datasource/pago_datasource.dart';

class PagoRepository {
  final _ds = PagoDatasource();

  Future<Map<String, dynamic>> crearPaymentIntent({
    required int incidenteId,
    required double montoTotal,
  }) => _ds.crearPaymentIntent(
        incidenteId: incidenteId,
        montoTotal: montoTotal,
      );

  Future<Map<String, dynamic>> confirmarPago({
    required int incidenteId,
    required String paymentIntentId,
    required double montoTotal,
  }) => _ds.confirmarPago(
        incidenteId: incidenteId,
        paymentIntentId: paymentIntentId,
        montoTotal: montoTotal,
      );

  Future<Map<String, dynamic>> obtenerPago(int incidenteId) =>
      _ds.obtenerPago(incidenteId);

  Future<List<Map<String, dynamic>>> listarMisPagos() =>
    _ds.listarMisPagos();
}