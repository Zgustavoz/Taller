import 'package:equatable/equatable.dart';

class NotificacionEntity extends Equatable {
  final int id;
  final String tipoDestinatario;
  final int? incidenteId;
  final String? titulo;
  final String? cuerpo;
  final Map<String, dynamic>? datosExtra;
  final String estado;
  final DateTime? enviadoEn;
  final DateTime? leidoEn;
  final DateTime creadoEn;

  const NotificacionEntity({
    required this.id,
    required this.tipoDestinatario,
    this.incidenteId,
    this.titulo,
    this.cuerpo,
    this.datosExtra,
    required this.estado,
    this.enviadoEn,
    this.leidoEn,
    required this.creadoEn,
  });

  bool get esLeida => leidoEn != null;
  bool get esEnviada => estado == 'enviado' || estado == 'leido';

  @override
  List<Object?> get props => [id, estado, leidoEn];
}