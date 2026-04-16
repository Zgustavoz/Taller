import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class IncidenteEvent extends Equatable {
  const IncidenteEvent();
  @override
  List<Object?> get props => [];
}

class IncidenteCargarMios extends IncidenteEvent {}

class IncidenteCargarTipos extends IncidenteEvent {}

class IncidenteCrear extends IncidenteEvent {
  final double latitud;
  final double longitud;
  final String? textoDireccion;
  final String? descripcion;
  final int? tipoIncidenteId;
  final int? nivelPrioridad;
  final List<File> archivos;

  const IncidenteCrear({
    required this.latitud,
    required this.longitud,
    this.textoDireccion,
    this.descripcion,
    this.tipoIncidenteId,
    this.nivelPrioridad,
    this.archivos = const [],
  });

  @override
  List<Object?> get props => [latitud, longitud];
}

class IncidenteCargarDetalle extends IncidenteEvent {
  final int id;
  const IncidenteCargarDetalle(this.id);
  @override
  List<Object?> get props => [id];
}

class IncidenteSubirArchivos extends IncidenteEvent {
  final int incidenteId;
  final List<File> archivos;
  const IncidenteSubirArchivos(this.incidenteId, this.archivos);
  @override
  List<Object?> get props => [incidenteId];
}

class IncidenteEliminarMultimedia extends IncidenteEvent {
  final int multimediaId;
  final int incidenteId;
  const IncidenteEliminarMultimedia(this.multimediaId, this.incidenteId);
  @override
  List<Object?> get props => [multimediaId];
}