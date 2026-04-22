import 'package:equatable/equatable.dart';
import 'multimedia_entity.dart';

class FichaResumen extends Equatable {
  final String problemaPrincipal;
  final String recomendacion;
  final String urgencia;
  final List<String> herramientasNecesarias;
  final String especialidadRequerida;

  const FichaResumen({
    required this.problemaPrincipal,
    required this.recomendacion,
    required this.urgencia,
    required this.herramientasNecesarias,
    required this.especialidadRequerida,
  });

  factory FichaResumen.fromJson(Map<String, dynamic> json) => FichaResumen(
        problemaPrincipal: json['problema_principal'] ?? '',
        recomendacion: json['recomendacion'] ?? '',
        urgencia: json['urgencia'] ?? 'media',
        herramientasNecesarias:
            List<String>.from(json['herramientas_necesarias'] ?? []),
        especialidadRequerida: json['especialidad_requerida'] ?? 'general',
      );

  @override
  List<Object?> get props => [problemaPrincipal, urgencia];
}

class AnalisisIA extends Equatable {
  final String tipoDetectado;
  final double confianza;
  final int nivelPrioridad;
  final String? transcripcionAudio;
  final String resumen;
  final FichaResumen? fichaResumen;
  final List<String> danosDetectados;
  final List<String> palabrasClave;

  const AnalisisIA({
    required this.tipoDetectado,
    required this.confianza,
    required this.nivelPrioridad,
    this.transcripcionAudio,
    required this.resumen,
    this.fichaResumen,
    required this.danosDetectados,
    required this.palabrasClave,
  });

  factory AnalisisIA.fromJson(Map<String, dynamic> json) {
    String? transcripcionAudio = json['transcripcion_audio'];
    if (transcripcionAudio != null) {
      final texto = transcripcionAudio.toString().trim();
      if (texto.toLowerCase() == 'no hay audio' ||
          texto.toLowerCase() == 'null' ||
          texto.toLowerCase() == 'nulo' ||
          texto.toLowerCase() ==
              'texto transcrito del audio si existe, o null si no hay audio') {
        transcripcionAudio = null;
      } else {
        transcripcionAudio = texto;
      }
    }

    return AnalisisIA(
      tipoDetectado: json['tipo_detectado'] ?? 'other',
      confianza: (json['confianza'] as num?)?.toDouble() ?? 0.0,
      nivelPrioridad: json['nivel_prioridad'] ?? 3,
      transcripcionAudio: transcripcionAudio,
      resumen: json['resumen'] ?? '',
      fichaResumen: json['ficha_resumen'] != null
          ? FichaResumen.fromJson(json['ficha_resumen'])
          : null,
      danosDetectados: List<String>.from(json['danos_detectados'] ?? []),
      palabrasClave: List<String>.from(json['palabras_clave'] ?? []),
    );
  }

  @override
  List<Object?> get props => [tipoDetectado, confianza];
}

class HistorialItem extends Equatable {
  final String? estadoAnterior;
  final String estadoNuevo;
  final String tipoActor;
  final String? notas;
  final DateTime creadoAt;

  const HistorialItem({
    this.estadoAnterior,
    required this.estadoNuevo,
    required this.tipoActor,
    this.notas,
    required this.creadoAt,
  });

  factory HistorialItem.fromJson(Map<String, dynamic> json) => HistorialItem(
        estadoAnterior: json['estado_anterior'],
        estadoNuevo: json['estado_nuevo'],
        tipoActor: json['tipo_actor'],
        notas: json['notas'],
        creadoAt: DateTime.parse(json['creado_at']),
      );

  @override
  List<Object?> get props => [estadoNuevo, creadoAt];
}

class AsignacionItem extends Equatable {
  final int tallerId;
  final String? nombreTaller;   
  final String? telefonoTaller; 
  final String estado;
  final double? distanciaKm;
  final double? puntuacion;

  const AsignacionItem({
    required this.tallerId,
    this.nombreTaller,
    this.telefonoTaller,
    required this.estado,
    this.distanciaKm,
    this.puntuacion,
  });

  factory AsignacionItem.fromJson(Map<String, dynamic> json) => AsignacionItem(
        tallerId: (json['taller_id'] as num?)?.toInt() ?? 0,
        nombreTaller: json['nombre_taller'],    // ← del backend
        telefonoTaller: json['telefono_taller'],
        estado: json['estado'] ?? 'pendiente',
        distanciaKm: (json['distancia_km'] as num?)?.toDouble(),
        puntuacion: (json['puntuacion'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [tallerId, estado];
}

class IncidenteEntity extends Equatable {
  final int id;
  final int usuarioId;
  final int? vehiculoId;
  final int? tallerAsignadoId;
  final int? tecnicoAsignadoId;
  final int? tipoIncidenteId;
  final double? latitud;
  final double? longitud;
  final String? textoDireccion;
  final String? descripcion;
  final String estado;
  final int? nivelPrioridad;
  final AnalisisIA? analisisIa;
  final FichaResumen? fichaResumen;
  final int? tiempoEstimadoLlegadaMin;
  final DateTime creadoAt;
  final DateTime? resueltaAt;
  final List<MultimediaEntity> multimedia;
  final List<HistorialItem> historial;
  final List<AsignacionItem> asignaciones;
  final int tallersNotificados;

  const IncidenteEntity({
    required this.id,
    required this.usuarioId,
    this.vehiculoId,
    this.tallerAsignadoId,
    this.tecnicoAsignadoId,
    this.tipoIncidenteId,
    this.latitud,
    this.longitud,
    this.textoDireccion,
    this.descripcion,
    required this.estado,
    this.nivelPrioridad,
    this.analisisIa,
    this.fichaResumen,
    this.tiempoEstimadoLlegadaMin,
    required this.creadoAt,
    this.resueltaAt,
    this.multimedia = const [],
    this.historial = const [],
    this.asignaciones = const [],
    this.tallersNotificados = 0,
  });

  bool get tieneIa => analisisIa != null;
  bool get estaActivo =>
      estado != 'resuelto' && estado != 'cancelado';

  @override
  List<Object?> get props => [id, estado];
}