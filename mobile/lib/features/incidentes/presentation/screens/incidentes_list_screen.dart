import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../bloc/incidente_bloc.dart';
import '../bloc/incidente_event.dart';
import '../bloc/incidente_state.dart';
import '../../domain/entities/incidente_entity.dart';

class IncidentesListScreen extends StatelessWidget {
  const IncidentesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidenteBloc()..add(IncidenteCargarMios()),
      child: const _IncidentesListView(),
    );
  }
}

class _IncidentesListView extends StatelessWidget {
  const _IncidentesListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Mis Incidentes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<IncidenteBloc>().add(IncidenteCargarMios()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/incidentes/crear').then((_) =>
            context.read<IncidenteBloc>().add(IncidenteCargarMios())),
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Reportar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: BlocBuilder<IncidenteBloc, IncidenteState>(
        builder: (context, state) {
          if (state is IncidenteLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (state is IncidenteError) {
            return _ErrorView(mensaje: state.mensaje,
                onRetry: () => context.read<IncidenteBloc>().add(IncidenteCargarMios()));
          }
          if (state is IncidenteListaCargada) {
            if (state.incidentes.isEmpty) return const _EmptyView();
            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () async =>
                  context.read<IncidenteBloc>().add(IncidenteCargarMios()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.incidentes.length,
                itemBuilder: (_, i) =>
                    _IncidenteCard(incidente: state.incidentes[i]),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _IncidenteCard extends StatelessWidget {
  final IncidenteEntity incidente;
  const _IncidenteCard({required this.incidente});

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente': return const Color(0xFFF59E0B);
      case 'analizando': return const Color(0xFF3B82F6);
      case 'asignado': return const Color(0xFF8B5CF6);
      case 'en_progreso': return const Color(0xFFEC4899);
      case 'resuelto': return const Color(0xFF10B981);
      case 'cancelado': return const Color(0xFF6B7280);
      default: return Colors.grey;
    }
  }

  IconData _iconEstado(String estado) {
    switch (estado) {
      case 'pendiente': return Icons.hourglass_empty_rounded;
      case 'analizando': return Icons.psychology_rounded;
      case 'asignado': return Icons.person_pin_rounded;
      case 'en_progreso': return Icons.build_rounded;
      case 'resuelto': return Icons.check_circle_rounded;
      case 'cancelado': return Icons.cancel_rounded;
      default: return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(incidente.estado);
    return GestureDetector(
      onTap: () => context.push('/incidentes/${incidente.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // Header de color según estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconEstado(incidente.estado), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Incidente #${incidente.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      incidente.estado.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (incidente.descripcion != null)
                    Text(
                      incidente.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incidente.textoDireccion ?? 'Ubicación registrada',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.photo_library_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${incidente.multimedia.length} archivos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatFecha(incidente.creadoAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.car_crash_rounded,
                size: 56, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          const Text('Sin incidentes',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Toca el botón para reportar una emergencia',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorView({required this.mensaje, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          Text(mensaje, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}