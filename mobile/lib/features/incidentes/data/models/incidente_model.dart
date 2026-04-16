import '../../domain/entities/incidente_entity.dart';
import 'multimedia_model.dart';

class IncidenteModel extends IncidenteEntity {
  const IncidenteModel({
    required super.id,
    required super.usuarioId,
    super.tallerAsignadoId,
    super.tipoIncidenteId,
    super.latitud,
    super.longitud,
    super.textoDireccion,
    super.descripcion,
    required super.estado,
    super.nivelPrioridad,
    super.analisisIa,
    super.tiempoEstimadoLlegadaMin,
    required super.creadoAt,
    super.resueltaAt,
    super.multimedia,
  });

  factory IncidenteModel.fromJson(Map<String, dynamic> json) => IncidenteModel(
        id: json['id'],
        usuarioId: json['usuario_id'],
        tallerAsignadoId: json['taller_asignado_id'],
        tipoIncidenteId: json['tipo_incidente_id'],
        latitud: (json['latitud'] as num?)?.toDouble(),
        longitud: (json['longitud'] as num?)?.toDouble(),
        textoDireccion: json['texto_direccion'],
        descripcion: json['descripcion'],
        estado: json['estado'] ?? 'pendiente',
        nivelPrioridad: json['nivel_prioridad'],
        analisisIa: json['analisis_ia'],
        tiempoEstimadoLlegadaMin: json['tiempo_estimado_llegada_min'],
        creadoAt: DateTime.parse(json['creado_at']),
        resueltaAt: json['resuelto_at'] != null
            ? DateTime.parse(json['resuelto_at'])
            : null,
        multimedia: (json['multimedia'] as List<dynamic>?)
                ?.map((m) => MultimediaModel.fromJson(m))
                .toList() ??
            [],
      );
}