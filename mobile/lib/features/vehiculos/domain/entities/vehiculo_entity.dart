import 'package:equatable/equatable.dart';

class VehiculoEntity extends Equatable {
  final int id;
  final int usuarioId;
  final String marca;
  final String modelo;
  final int year;
  final String placa;
  final String? color;
  final String? tipo;
  final String? urlFoto;
  final bool estado;
  final DateTime fechaCreacion;

  const VehiculoEntity({
    required this.id,
    required this.usuarioId,
    required this.marca,
    required this.modelo,
    required this.year,
    required this.placa,
    this.color,
    this.tipo,
    this.urlFoto,
    required this.estado,
    required this.fechaCreacion,
  });

  String get nombreCompleto => '$marca $modelo $year';

  @override
  List<Object?> get props => [id, placa];
}