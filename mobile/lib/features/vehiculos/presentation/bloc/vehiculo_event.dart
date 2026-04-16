import 'package:equatable/equatable.dart';

abstract class VehiculoEvent extends Equatable {
  const VehiculoEvent();
  @override
  List<Object?> get props => [];
}

class VehiculoCargar extends VehiculoEvent {}

class VehiculoCrear extends VehiculoEvent {
  final Map<String, dynamic> data;
  const VehiculoCrear(this.data);
  @override
  List<Object?> get props => [data];
}

class VehiculoEliminar extends VehiculoEvent {
  final int id;
  const VehiculoEliminar(this.id);
  @override
  List<Object?> get props => [id];
}