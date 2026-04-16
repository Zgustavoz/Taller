import 'package:equatable/equatable.dart';
import '../../domain/entities/vehiculo_entity.dart';

abstract class VehiculoState extends Equatable {
  const VehiculoState();
  @override
  List<Object?> get props => [];
}

class VehiculoInitial extends VehiculoState {}
class VehiculoLoading extends VehiculoState {}

class VehiculoCargado extends VehiculoState {
  final List<VehiculoEntity> vehiculos;
  const VehiculoCargado(this.vehiculos);
  @override
  List<Object?> get props => [vehiculos];
}

class VehiculoCreadoExito extends VehiculoState {}
class VehiculoEliminadoExito extends VehiculoState {}

class VehiculoError extends VehiculoState {
  final String mensaje;
  const VehiculoError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}