import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/vehiculo_repository.dart';
import 'vehiculo_event.dart';
import 'vehiculo_state.dart';

class VehiculoBloc extends Bloc<VehiculoEvent, VehiculoState> {
  final _repo = VehiculoRepository();

  VehiculoBloc() : super(VehiculoInitial()) {
    on<VehiculoCargar>(_onCargar);
    on<VehiculoCrear>(_onCrear);
    on<VehiculoEliminar>(_onEliminar);
  }

  Future<void> _onCargar(VehiculoCargar e, Emitter emit) async {
    emit(VehiculoLoading());
    try {
      final vehiculos = await _repo.misVehiculos();
      emit(VehiculoCargado(vehiculos));
    } catch (e) {
      emit(VehiculoError(e.toString()));
    }
  }

  Future<void> _onCrear(VehiculoCrear e, Emitter emit) async {
    emit(VehiculoLoading());
    try {
      await _repo.crear(e.data);
      emit(VehiculoCreadoExito());
      add(VehiculoCargar());
    } catch (e) {
      emit(VehiculoError(e.toString()));
    }
  }

  Future<void> _onEliminar(VehiculoEliminar e, Emitter emit) async {
    try {
      await _repo.eliminar(e.id);
      emit(VehiculoEliminadoExito());
      add(VehiculoCargar());
    } catch (e) {
      emit(VehiculoError(e.toString()));
    }
  }
}