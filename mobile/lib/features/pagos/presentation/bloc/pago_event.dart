import 'package:equatable/equatable.dart';

abstract class PagoEvent extends Equatable {
  const PagoEvent();
  @override
  List<Object?> get props => [];
}

class PagoVerificar extends PagoEvent {
  final int incidenteId;
  const PagoVerificar(this.incidenteId);
  @override
  List<Object?> get props => [incidenteId];
}

class PagoIniciar extends PagoEvent {
  final int incidenteId;
  final double monto;
  const PagoIniciar({required this.incidenteId, required this.monto});
  @override
  List<Object?> get props => [incidenteId, monto];
}

class PagoConfirmar extends PagoEvent {
  final int incidenteId;
  final String paymentIntentId;
  final double monto;
  const PagoConfirmar({
    required this.incidenteId,
    required this.paymentIntentId,
    required this.monto,
  });
  @override
  List<Object?> get props => [incidenteId, paymentIntentId];
}

class PagoCargarLista extends PagoEvent {}