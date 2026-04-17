import 'package:equatable/equatable.dart';

abstract class VehiculoEvent extends Equatable {
  const VehiculoEvent();
  @override
  List<Object?> get props => [];
}

class VehiculoCargar extends VehiculoEvent {}

class VehiculoCrear extends VehiculoEvent {
  final Map<String, dynamic> data;
  final String? fotoPath;
  const VehiculoCrear(this.data, {this.fotoPath});
  @override
  List<Object?> get props => [data, fotoPath];
}

class VehiculoEliminar extends VehiculoEvent {
  final int id;
  const VehiculoEliminar(this.id);
  @override
  List<Object?> get props => [id];
}