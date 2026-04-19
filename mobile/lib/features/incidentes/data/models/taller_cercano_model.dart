class TallerCercanoModel {
  final int id;
  final String nombre;
  final String? telefono;
  final List<String> especialidades;
  final double calificacion;
  final bool estaDisponible;
  final double? latitud;    // ← NUEVO
  final double? longitud;   // ← NUEVO

  TallerCercanoModel({
    required this.id,
    required this.nombre,
    this.telefono,
    required this.especialidades,
    required this.calificacion,
    required this.estaDisponible,
    this.latitud,
    this.longitud,
  });

  factory TallerCercanoModel.fromJson(Map<String, dynamic> json) =>
      TallerCercanoModel(
        id: json['id'],
        nombre: json['nombre'],
        telefono: json['telefono'],
        especialidades: List<String>.from(json['especialidades'] ?? []),
        calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
        estaDisponible: json['esta_disponible'] ?? true,
        latitud: (json['latitud'] as num?)?.toDouble(),    // ← NUEVO
        longitud: (json['longitud'] as num?)?.toDouble(),  // ← NUEVO
      );
}