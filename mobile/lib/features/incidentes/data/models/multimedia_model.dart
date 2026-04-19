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

  factory MultimediaModel.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo_archivo'] ?? json['tipo'];
    final url = json['url_almacenamiento'] ?? json['url'];
    final subidoAtValue = json['subido_at'] ?? json['creado_at'];

    return MultimediaModel(
      id: json['id'],
      incidenteId: json['incidente_id'] ?? 0,
      tipoArchivo: tipo as String,
      urlAlmacenamiento: url as String,
      tipoMime: json['tipo_mime'],
      duracionSeg: (json['duracion_seg'] as num?)?.toDouble(),
      tamanoArchivoBytes: json['tamano_archivo_bytes'],
      resultadoIa: json['resultado_ia'],
      subidoAt: subidoAtValue != null
          ? DateTime.parse(subidoAtValue as String)
          : DateTime.now(),
    );
  }
}