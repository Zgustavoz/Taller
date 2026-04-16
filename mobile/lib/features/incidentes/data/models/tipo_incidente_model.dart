class TipoIncidenteModel {
  final int id;
  final String codigo;
  final String nombre;
  final int? prioridadBase;

  TipoIncidenteModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.prioridadBase,
  });

  factory TipoIncidenteModel.fromJson(Map<String, dynamic> json) =>
      TipoIncidenteModel(
        id: json['id'],
        codigo: json['codigo'],
        nombre: json['nombre'],
        prioridadBase: json['prioridad_base'],
      );
}