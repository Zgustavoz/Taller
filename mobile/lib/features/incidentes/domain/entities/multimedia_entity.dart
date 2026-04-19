import 'package:equatable/equatable.dart';

class MultimediaEntity extends Equatable {
  final int id;
  final int incidenteId;
  final String tipoArchivo;
  final String urlAlmacenamiento;
  final String? tipoMime;
  final double? duracionSeg;
  final int? tamanoArchivoBytes;
  final dynamic resultadoIa;
  final DateTime subidoAt;

  const MultimediaEntity({
    required this.id,
    required this.incidenteId,
    required this.tipoArchivo,
    required this.urlAlmacenamiento,
    this.tipoMime,
    this.duracionSeg,
    this.tamanoArchivoBytes,
    this.resultadoIa,
    required this.subidoAt,
  });

  @override
  List<Object?> get props => [id];
}