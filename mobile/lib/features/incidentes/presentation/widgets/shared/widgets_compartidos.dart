import 'package:flutter/material.dart';
import 'package:mobile/core/config/theme/app_theme.dart';


// ─── Tarjeta ──────────────────────────────────────────────────
class Tarjeta extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? border;
  const Tarjeta({super.key, required this.child, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: border != null ? Border.all(color: border!) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────
class Badge extends StatelessWidget {
  final String texto;
  final Color color;
  const Badge({super.key, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ─── TituloSeccion ────────────────────────────────────────────
class TituloSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  const TituloSeccion(
      {super.key,
      required this.icono,
      required this.titulo,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary)),
      ),
    ]);
  }
}

// ─── Seccion (para formularios) ───────────────────────────────
class Seccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  const Seccion({super.key, required this.icono, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: AppTheme.accent, size: 18),
      ),
      const SizedBox(width: 10),
      Text(titulo,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary)),
    ]);
  }
}

// ─── FilaDetalle ──────────────────────────────────────────────
class FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  const FilaDetalle(
      {super.key,
      required this.icono,
      required this.label,
      required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, size: 16, color: AppTheme.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ]),
    );
  }
}