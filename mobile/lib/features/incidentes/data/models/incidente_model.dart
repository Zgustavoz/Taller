import '../../domain/entities/incidente_entity.dart';
import 'multimedia_model.dart';
import 'dart:convert';

class IncidenteModel extends IncidenteEntity {
  const IncidenteModel({
    required super.id,
    required super.usuarioId,
    super.vehiculoId,
    super.tallerAsignadoId,
    super.tecnicoAsignadoId,
    super.tipoIncidenteId,
    super.latitud,
    super.longitud,
    super.textoDireccion,
    super.descripcion,
    required super.estado,
    super.nivelPrioridad,
    super.analisisIa,
    super.fichaResumen,
    super.tiempoEstimadoLlegadaMin,
    required super.creadoAt,
    super.resueltaAt,
    super.multimedia,
    super.historial,
    super.asignaciones,
    super.tallersNotificados,
  });

  factory IncidenteModel.fromJson(Map<String, dynamic> json) {
    // Parsear análisis IA
    AnalisisIA? analisisIa;
    FichaResumen? fichaResumen;

    if (json['analisis_ia'] != null) {
      try {
        final iaData = json['analisis_ia'] is String
            ? _parseJson(json['analisis_ia'])
            : json['analisis_ia'] as Map<String, dynamic>;
        analisisIa = AnalisisIA.fromJson(iaData);
      } catch (_) {}
    }

    if (json['ficha_resumen'] != null) {
      try {
        final fichaData = json['ficha_resumen'] is String
            ? _parseJson(json['ficha_resumen'])
            : json['ficha_resumen'] as Map<String, dynamic>;
        fichaResumen = FichaResumen.fromJson(fichaData);
      } catch (_) {}
    }

    return IncidenteModel(
      id: (json['id'] as int?) ?? 0,
      usuarioId: (json['usuario_id'] as int?) ?? 0,
      vehiculoId: json['vehiculo_id'],
      tallerAsignadoId: json['taller_asignado_id'],
      tecnicoAsignadoId: json['tecnico_asignado_id'],
      tipoIncidenteId: json['tipo_incidente_id'],
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      textoDireccion: json['texto_direccion'],
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'pendiente',
      nivelPrioridad: json['nivel_prioridad'],
      analisisIa: analisisIa,
      fichaResumen: fichaResumen,
      tiempoEstimadoLlegadaMin: json['tiempo_estimado_llegada_min'],
      creadoAt: DateTime.parse(json['creado_at']),
      resueltaAt: json['resuelto_at'] != null
          ? DateTime.parse(json['resuelto_at'])
          : null,
      multimedia: (json['multimedia'] as List<dynamic>?)
              ?.map((m) => MultimediaModel.fromJson(m))
              .toList() ??
          [],
      historial: (json['historial'] as List<dynamic>?)
              ?.map((h) => HistorialItem.fromJson(h))
              .toList() ??
          [],
      asignaciones: (json['asignaciones'] as List<dynamic>?)
              ?.map((a) => AsignacionItem.fromJson(a))
              .toList() ??
          [],
      tallersNotificados: json['talleres_notificados'] ?? 0,
    );
  }

  static Map<String, dynamic> _parseJson(String texto) {
    return jsonDecode(texto) as Map<String, dynamic>;
  }
}