import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/incidente_repository.dart';
import 'incidente_event.dart';
import 'incidente_state.dart';

class IncidenteBloc extends Bloc<IncidenteEvent, IncidenteState> {
  final _repo = IncidenteRepository();

  IncidenteBloc() : super(IncidenteInitial()) {
    on<IncidenteCargarMios>(_onCargarMios);
    on<IncidenteCargarTipos>(_onCargarTipos);
    on<IncidenteCrear>(_onCrear);
    on<IncidenteCargarDetalle>(_onDetalle);
    on<IncidenteSubirArchivos>(_onSubirArchivos);
    on<IncidenteEliminarMultimedia>(_onEliminarMultimedia);
  }

  Future<void> _onCargarMios(IncidenteCargarMios e, Emitter emit) async {
    emit(IncidenteLoading());
    try {
      final incidentes = await _repo.misIncidentes();
      final tipos = await _repo.listarTipos();
      emit(IncidenteListaCargada(incidentes, tipos));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onCargarTipos(IncidenteCargarTipos e, Emitter emit) async {}

  Future<void> _onCrear(IncidenteCrear e, Emitter emit) async {
    emit(IncidenteLoading());
    try {
      final incidente = await _repo.crear(
        latitud: e.latitud,
        longitud: e.longitud,
        textoDireccion: e.textoDireccion,
        descripcion: e.descripcion,
        tipoIncidenteId: e.tipoIncidenteId,
        nivelPrioridad: e.nivelPrioridad,
      );
      if (e.archivos.isNotEmpty) {
        await _repo.subirArchivos(incidente.id, e.archivos);
      }
      emit(IncidenteCreadoExito(incidente));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onDetalle(IncidenteCargarDetalle e, Emitter emit) async {
    emit(IncidenteLoading());
    try {
      final incidente = await _repo.obtener(e.id);
      emit(IncidenteDetalleCargado(incidente));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onSubirArchivos(IncidenteSubirArchivos e, Emitter emit) async {
    emit(IncidenteLoading());
    try {
      await _repo.subirArchivos(e.incidenteId, e.archivos);
      final incidente = await _repo.obtener(e.incidenteId);
      emit(IncidenteDetalleCargado(incidente));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }

  Future<void> _onEliminarMultimedia(IncidenteEliminarMultimedia e, Emitter emit) async {
    try {
      await _repo.eliminarMultimedia(e.multimediaId);
      final incidente = await _repo.obtener(e.incidenteId);
      emit(IncidenteDetalleCargado(incidente));
    } catch (e) {
      emit(IncidenteError(e.toString()));
    }
  }
}