import '../../domain/entities/notificacion_entity.dart';

class NotificacionModel extends NotificacionEntity {
  const NotificacionModel({
    required super.id,
    required super.tipoDestinatario,
    super.incidenteId,
    super.titulo,
    super.cuerpo,
    super.datosExtra,
    required super.estado,
    super.enviadoEn,
    super.leidoEn,
    required super.creadoEn,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) =>
      NotificacionModel(
        id: json['id'],
        tipoDestinatario: json['tipo_destinatario'] ?? 'usuario',
        incidenteId: json['incidente_id'],
        titulo: json['titulo'],
        cuerpo: json['cuerpo'],
        datosExtra: json['datos_extra'] is Map
            ? Map<String, dynamic>.from(json['datos_extra'])
            : null,
        estado: json['estado'] ?? 'pendiente',
        enviadoEn: json['enviado_en'] != null
            ? DateTime.tryParse(json['enviado_en'])
            : null,
        leidoEn: json['leido_en'] != null
            ? DateTime.tryParse(json['leido_en'])
            : null,
        creadoEn: DateTime.parse(json['creado_en']),
      );
}