import '../../domain/entities/multimedia_entity.dart';

class MultimediaModel extends MultimediaEntity {
  const MultimediaModel({
    required super.id,
    required super.incidenteId,
    required super.tipoArchivo,
    required super.urlAlmacenamiento,
    super.tipoMime,
    super.duracionSeg,
    super.tamanoArchivoBytes,
    super.resultadoIa,
    required super.subidoAt,
  });

  factory MultimediaModel.fromJson(Map<String, dynamic> json) => MultimediaModel(
        id: json['id'],
        incidenteId: json['incidente_id'],
        tipoArchivo: json['tipo_archivo'],
        urlAlmacenamiento: json['url_almacenamiento'],
        tipoMime: json['tipo_mime'],
        duracionSeg: (json['duracion_seg'] as num?)?.toDouble(),
        tamanoArchivoBytes: json['tamano_archivo_bytes'],
        resultadoIa: json['resultado_ia'],
        subidoAt: DateTime.parse(json['subido_at']),
      );
}