import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/theme/app_theme.dart';

import '../../../incidentes/domain/entities/incidente_entity.dart';

// ─── Emergencia activa ─────────────────────────────────────────

class EmergenciaActivaCard extends StatelessWidget {
  final IncidenteEntity incidente;
  const EmergenciaActivaCard({super.key, required this.incidente});

  Color get _color {
    switch (incidente.estado) {
      case 'analizando': return const Color(0xFF3B82F6);
      case 'asignado': return const Color(0xFF8B5CF6);
      case 'en_progreso': return const Color(0xFFEC4899);
      default: return const Color(0xFFF59E0B);
    }
  }

  String get _estadoLabel =>
      incidente.estado.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: _color.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 8),
                    const SizedBox(width: 6),
                    Text(_estadoLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              const Text('Emergencia activa',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          if (incidente.descripcion != null)
            Text(incidente.descripcion!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary)),
          if (incidente.tiempoEstimadoLlegadaMin != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: AppTheme.accent),
                const SizedBox(width: 6),
                Text(
                  'ETA: ${incidente.tiempoEstimadoLlegadaMin} minutos',
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  context.push('/incidentes/${incidente.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _color,
                side: BorderSide(color: _color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ver detalles'),
            ),
          ),
        ],
      ),
    );
  }
}

 
// ─── Incidente resumen card ────────────────────────────────────

class IncidenteResumenCard extends StatelessWidget {
  final IncidenteEntity incidente;
  const IncidenteResumenCard({super.key, required this.incidente});

  Color _color(String e) {
    switch (e) {
      case 'pendiente': return const Color(0xFFF59E0B);
      case 'analizando': return const Color(0xFF3B82F6);
      case 'asignado': return const Color(0xFF8B5CF6);
      case 'en_progreso': return const Color(0xFFEC4899);
      case 'resuelto': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(incidente.estado);
    return GestureDetector(
      onTap: () => context.push('/incidentes/${incidente.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.car_crash_rounded, color: c, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incidente.descripcion ?? 'Incidente #${incidente.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${incidente.creadoAt.day}/${incidente.creadoAt.month}/${incidente.creadoAt.year}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                incidente.estado.replaceAll('_', ' '),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SinIncidentes extends StatelessWidget {
  const SinIncidentes({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 48, color: Colors.green.shade400),
          const SizedBox(height: 12),
          const Text('Sin emergencias registradas',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('Todo en orden 🚗',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
