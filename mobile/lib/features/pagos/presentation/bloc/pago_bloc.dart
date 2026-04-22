import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/pago_repository.dart';
import 'pago_event.dart';
import 'pago_state.dart';

class PagoBloc extends Bloc<PagoEvent, PagoState> {
  final _repo = PagoRepository();

  PagoBloc() : super(PagoInicial()) {
    on<PagoVerificar>(_onVerificar);
    on<PagoIniciar>(_onIniciar);
    on<PagoConfirmar>(_onConfirmar);
    on<PagoCargarLista>(_onCargarLista);
  }

  Future<void> _onVerificar(PagoVerificar e, Emitter emit) async {
    emit(PagoCargando());
    try {
      final data = await _repo.obtenerPago(e.incidenteId);
      if (data['tiene_pago'] == true && data['estado_pago'] == 'completado') {
        emit(PagoYaCompletado(data));
      } else {
        emit(PagoListo());
      }
    } catch (_) {
      emit(PagoListo()); // si falla la consulta, dejar pagar
    }
  }

  Future<void> _onIniciar(PagoIniciar e, Emitter emit) async {
    emit(PagoCargando());
    try {
      final data = await _repo.crearPaymentIntent(
        incidenteId: e.incidenteId,
        montoTotal: e.monto,
      );
      emit(PagoIntentCreado(
        clientSecret: data['client_secret'],
        paymentIntentId: data['payment_intent_id'],
        monto: (data['monto_total'] as num).toDouble(),
        comision: (data['monto_comision'] as num).toDouble(),
        montoTaller: (data['monto_taller'] as num).toDouble(),
      ));
    } catch (e) {
      emit(PagoError('Error al iniciar el pago: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmar(PagoConfirmar e, Emitter emit) async {
    emit(PagoCargando());
    try {
      await _repo.confirmarPago(
        incidenteId: e.incidenteId,
        paymentIntentId: e.paymentIntentId,
        montoTotal: e.monto,
      );
      emit(PagoExitoso(
        monto: e.monto,
        comision: e.monto * 0.10,
        montoTaller: e.monto * 0.90,
      ));
    } catch (err) {
      emit(PagoError('Error al confirmar el pago: ${err.toString()}'));
    }
  }

  Future<void> _onCargarLista( PagoCargarLista e, Emitter emit ) async {
    emit(PagoCargando());
    try {
      final lista = await _repo.listarMisPagos();
      emit(PagoListaCargada(lista));
    } catch (err) {
      emit(PagoError( 'Error cargando pagos: ${err.toString()}',),);
    }
  }
}