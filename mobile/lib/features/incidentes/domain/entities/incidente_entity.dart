import 'package:equatable/equatable.dart';
import 'multimedia_entity.dart';

class IncidenteEntity extends Equatable {
  final int id;
  final int usuarioId;
  final int? tallerAsignadoId;
  final int? tipoIncidenteId;
  final double? latitud;
  final double? longitud;
  final String? textoDireccion;
  final String? descripcion;
  final String estado;
  final int? nivelPrioridad;
  final String? analisisIa;
  final int? tiempoEstimadoLlegadaMin;
  final DateTime creadoAt;
  final DateTime? resueltaAt;
  final List<MultimediaEntity> multimedia;

  const IncidenteEntity({
    required this.id,
    required this.usuarioId,
    this.tallerAsignadoId,
    this.tipoIncidenteId,
    this.latitud,
    this.longitud,
    this.textoDireccion,
    this.descripcion,
    required this.estado,
    this.nivelPrioridad,
    this.analisisIa,
    this.tiempoEstimadoLlegadaMin,
    required this.creadoAt,
    this.resueltaAt,
    this.multimedia = const [],
  });

  @override
  List<Object?> get props => [id, estado];
}