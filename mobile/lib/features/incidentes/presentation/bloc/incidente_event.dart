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
  final int? vehiculoId;
  final int? nivelPrioridad;
  final List<File> archivos;
  final String? tipoNombre;

  const IncidenteCrear({
    required this.latitud,
    required this.longitud,
    this.textoDireccion,
    this.descripcion,
    this.tipoIncidenteId,
    this.vehiculoId,
    this.nivelPrioridad,
    required this.archivos,
    this.tipoNombre,
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

class IncidenteCargarTalleresCercanos extends IncidenteEvent {
  final int incidenteId;
  final double radioKm;
  const IncidenteCargarTalleresCercanos(this.incidenteId,
      {this.radioKm = 15.0});
  @override
  List<Object?> get props => [incidenteId];
}

class IncidenteCancelar extends IncidenteEvent {
  final int incidenteId;
  final String? motivo;
  const IncidenteCancelar(this.incidenteId, {this.motivo});
  @override
  List<Object?> get props => [incidenteId];
}

class IncidenteCalificar extends IncidenteEvent {
  final int incidenteId;
  final int puntuacion;
  final String? comentario;
  const IncidenteCalificar(this.incidenteId, this.puntuacion, {this.comentario});
  @override
  List<Object?> get props => [incidenteId, puntuacion];
}