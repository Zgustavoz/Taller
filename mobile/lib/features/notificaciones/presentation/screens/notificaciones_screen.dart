import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../domain/entities/notificacion_entity.dart';
import '../bloc/notificacion_bloc.dart';
import '../bloc/notificacion_event.dart';
import '../bloc/notificacion_state.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificacionBloc()..add(NotificacionCargar()),
      child: const _NotificacionesView(),
    );
  }
}

class _NotificacionesView extends StatelessWidget {
  const _NotificacionesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Notificaciones',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          BlocBuilder<NotificacionBloc, NotificacionState>(
            builder: (context, state) {
              if (state is NotificacionCargada &&
                  state.noLeidas > 0) {
                return TextButton(
                  onPressed: () => context
                      .read<NotificacionBloc>()
                      .add(NotificacionMarcarTodasLeidas()),
                  child: const Text(
                    'Marcar todas',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificacionBloc, NotificacionState>(
        builder: (context, state) {
          if (state is NotificacionLoading) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.accent));
          }

          if (state is NotificacionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.mensaje,
                      style:
                          TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<NotificacionBloc>()
                        .add(NotificacionCargar()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificacionCargada) {
            if (state.notificaciones.isEmpty) {
              return _EmptyView();
            }

            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () async => context
                  .read<NotificacionBloc>()
                  .add(NotificacionCargar()),
              child: Column(
                children: [
                  // Banner de no leídas
                  if (state.noLeidas > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      child: Text(
                        '${state.noLeidas} notificación${state.noLeidas > 1 ? 'es' : ''} sin leer',
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                      itemCount: state.notificaciones.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (_, i) => _NotificacionItem(
                        notif: state.notificaciones[i],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _NotificacionItem extends StatelessWidget {
  final NotificacionEntity notif;
  const _NotificacionItem({required this.notif});

  IconData get _icono {
    if (notif.titulo?.contains('aceptada') == true) {
      return Icons.check_circle_rounded;
    }
    if (notif.titulo?.contains('emergencia') == true ||
        notif.titulo?.contains('Nueva') == true) {
      return Icons.emergency_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color get _color {
    if (notif.titulo?.contains('aceptada') == true) {
      return const Color(0xFF10B981);
    }
    if (notif.titulo?.contains('emergencia') == true ||
        notif.titulo?.contains('Nueva') == true) {
      return AppTheme.error;
    }
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    final noLeida = !notif.esLeida;

    return InkWell(
      onTap: () {
        // Marcar como leída
        if (noLeida) {
          context
              .read<NotificacionBloc>()
              .add(NotificacionMarcarLeida(notif.id));
        }

        // Navegar al incidente si tiene uno
        if (notif.incidenteId != null) {
          context.push('/incidentes/${notif.incidenteId}');
        }
      },
      child: Container(
        color: noLeida
            ? AppTheme.accent.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icono, color: _color, size: 22),
            ),
            const SizedBox(width: 14),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        notif.titulo ?? 'Notificación',
                        style: TextStyle(
                            fontWeight: noLeida
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    if (noLeida)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle),
                      ),
                  ]),
                  if (notif.cuerpo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notif.cuerpo!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _formatFecha(notif.creadoEn),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400),
                    ),
                    if (notif.incidenteId != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ver incidente →',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime f) {
    final now = DateTime.now();
    final diff = now.difference(f);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return '${f.day}/${f.month}/${f.year}';
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_rounded,
                size: 52, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          const Text('Sin notificaciones',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Aquí verás las alertas de tus emergencias',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}