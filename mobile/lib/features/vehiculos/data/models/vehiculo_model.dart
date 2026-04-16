import '../../domain/entities/vehiculo_entity.dart';

class VehiculoModel extends VehiculoEntity {
  const VehiculoModel({
    required super.id,
    required super.usuarioId,
    required super.marca,
    required super.modelo,
    required super.year,
    required super.placa,
    super.color,
    super.tipo,
    super.urlFoto,
    required super.estado,
    required super.fechaCreacion,
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) => VehiculoModel(
        id: json['id'],
        usuarioId: json['usuario_id'],
        marca: json['marca'],
        modelo: json['modelo'],
        year: json['year'],
        placa: json['placa'],
        color: json['color'],
        tipo: json['tipo'],
        urlFoto: json['url_foto'],
        estado: json['estado'] ?? true,
        fechaCreacion: DateTime.parse(json['fecha_creacion']),
      );

  Map<String, dynamic> toJson() => {
        'marca': marca,
        'modelo': modelo,
        'year': year,
        'placa': placa,
        'color': color,
        'tipo': tipo,
        'url_foto': urlFoto,
        'estado': estado,
      };
}