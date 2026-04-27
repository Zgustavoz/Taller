import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/incidente_repository.dart';
import 'incidente_event.dart';
import 'incidente_state.dart';

class IncidenteBloc extends Bloc<IncidenteEvent, IncidenteState> {
  final _repo = IncidenteRepository();

  IncidenteBloc() : super(IncidenteInitial()) {
    on<IncidenteCargarMios>(_onCargarMios);
    on<IncidenteCrear>(_onCrear);
    on<IncidenteCargarDetalle>(_onDetalle);
    on<IncidenteSubirArchivos>(_onSubirArchivos);
    on<IncidenteEliminarMultimedia>(_onEliminarMultimedia);
    on<IncidenteCargarTalleresCercanos>(_onCargarTalleresCercanos);
    on<IncidenteCancelar>(_onCancelar);
    on<IncidenteCalificar>(_onCalificar);
  }

  Future<void> _onCargarMios(
      IncidenteCargarMios e, Emitter emit) async {
    if (state is! IncidenteListaCargada) {
      emit(IncidenteLoading());
    }
    try {
      final incidentes = await _repo.misIncidentes();
      final tipos = await _repo.listarTipos();
      emit(IncidenteListaCargada(incidentes, tipos));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onCrear(IncidenteCrear e, Emitter emit) async {
    // Mostrar estado "analizando" mientras Gemini procesa
    emit(const IncidenteAnalizando());
    try {
      final incidente = await _repo.crear(
        latitud: e.latitud,
        longitud: e.longitud,
        descripcion: e.descripcion,
        textoDireccion: e.textoDireccion,
        tipoIncidenteId: e.tipoIncidenteId,
        vehiculoId: e.vehiculoId,
        nivelPrioridad: e.nivelPrioridad,
        archivos: e.archivos,
      );
      emit(IncidenteCreadoExito(
        incidente,
        talleresNotificados: incidente.tallersNotificados,
      ));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onDetalle(
      IncidenteCargarDetalle e, Emitter emit) async {
      if (state is! IncidenteDetalleCargado) {
        emit(IncidenteLoading());
      }
    try {
      final incidente = await _repo.obtener(e.id);
      final talleres = await _repo.talleresCercanos(e.id, 15.0);
      emit(IncidenteDetalleCargado(incidente, talleresCercanos: talleres));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onSubirArchivos(
      IncidenteSubirArchivos e, Emitter emit) async {
    emit(IncidenteLoading());
    try {
      await _repo.subirArchivos(e.incidenteId, e.archivos);
      final incidente = await _repo.obtener(e.incidenteId);
      final talleres = await _repo.talleresCercanos(e.incidenteId, 15.0);
      emit(IncidenteDetalleCargado(incidente, talleresCercanos: talleres));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onEliminarMultimedia(
      IncidenteEliminarMultimedia e, Emitter emit) async {
    try {
      await _repo.eliminarMultimedia(e.multimediaId);
      final incidente = await _repo.obtener(e.incidenteId);
      final talleres =
          await _repo.talleresCercanos(e.incidenteId, 15.0);
      emit(IncidenteDetalleCargado(incidente, talleresCercanos: talleres));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onCargarTalleresCercanos(
      IncidenteCargarTalleresCercanos e, Emitter emit) async {
    try {
      final talleres =
          await _repo.talleresCercanos(e.incidenteId, e.radioKm);
      final incidente = await _repo.obtener(e.incidenteId);
      emit(IncidenteDetalleCargado(incidente, talleresCercanos: talleres));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onCancelar(IncidenteCancelar e, Emitter emit) async {
    emit(IncidenteLoading());
    try {
      await _repo.cancelar(e.incidenteId, motivo: e.motivo);
      emit(IncidenteCanceladoExito());
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onCalificar(IncidenteCalificar e, Emitter emit) async {
    emit(IncidenteLoading());
    try {
      final resultado = await _repo.calificar(
        e.incidenteId,
        puntuacion: e.puntuacion,
        comentario: e.comentario,
      );
      emit(IncidenteCalificadoExito(resultado['nuevo_promedio_taller'] ?? 0.0));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

}