import 'package:equatable/equatable.dart';

abstract class PagoState extends Equatable {
  const PagoState();
  @override
  List<Object?> get props => [];
}

class PagoInicial extends PagoState {}

class PagoCargando extends PagoState {}

// Pago ya existe y está completado
class PagoYaCompletado extends PagoState {
  final Map<String, dynamic> infoPago;
  const PagoYaCompletado(this.infoPago);
  @override
  List<Object?> get props => [infoPago];
}

// Sin pago previo → listo para pagar
class PagoListo extends PagoState {}

// PaymentIntent creado → Flutter debe abrir el Payment Sheet
class PagoIntentCreado extends PagoState {
  final String clientSecret;
  final String paymentIntentId;
  final double monto;
  final double comision;
  final double montoTaller;
  const PagoIntentCreado({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.monto,
    required this.comision,
    required this.montoTaller,
  });
  @override
  List<Object?> get props => [clientSecret];
}

// Pago completado exitosamente
class PagoExitoso extends PagoState {
  final double monto;
  final double comision;
  final double montoTaller;
  const PagoExitoso({
    required this.monto,
    required this.comision,
    required this.montoTaller,
  });
  @override
  List<Object?> get props => [monto];
}

class PagoError extends PagoState {
  final String mensaje;
  const PagoError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

class PagoListaCargada extends PagoState {
  final List<Map<String, dynamic>> pagos;

  const PagoListaCargada(this.pagos);

  @override
  List<Object?> get props => [pagos];
}