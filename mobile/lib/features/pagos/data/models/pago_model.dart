class PagoModel {
  final int id;
  final int idIncidente;
  final double montoTotal;
  final double montoComision;
  final double montoTaller;
  final String metodoPago;
  final String? referenciaExterna;
  final String estadoPago;
  final bool comisionPagada;
  final DateTime creadoEn;
  final DateTime? pagadoEn;

  const PagoModel({
    required this.id,
    required this.idIncidente,
    required this.montoTotal,
    required this.montoComision,
    required this.montoTaller,
    required this.metodoPago,
    this.referenciaExterna,
    required this.estadoPago,
    required this.comisionPagada,
    required this.creadoEn,
    this.pagadoEn,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) => PagoModel(
        id: json['id'],
        idIncidente: json['id_incidente'],
        montoTotal: (json['monto_total'] as num).toDouble(),
        montoComision: (json['monto_comision'] as num).toDouble(),
        montoTaller: (json['monto_taller'] as num).toDouble(),
        metodoPago: json['metodo_pago'] ?? 'tarjeta',
        referenciaExterna: json['referencia_externa'],
        estadoPago: json['estado_pago'] ?? 'pendiente',
        comisionPagada: json['comision_pagada'] ?? false,
        creadoEn: DateTime.parse(json['creado_en']),
        pagadoEn: json['pagado_en'] != null
            ? DateTime.parse(json['pagado_en'])
            : null,
      );
}