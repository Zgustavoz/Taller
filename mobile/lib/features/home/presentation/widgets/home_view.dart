import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/theme/app_theme.dart';

import '../../../incidentes/presentation/bloc/incidente_bloc.dart';
// import '../../../incidentes/presentation/bloc/incidente_event.dart';
import '../../../incidentes/presentation/bloc/incidente_state.dart';

import '../../../notificaciones/presentation/bloc/notificacion_bloc.dart';
import '../../../notificaciones/presentation/bloc/notificacion_state.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

import 'home_cards_widget.dart';
import 'incidente_widgets.dart';
import 'app_drawer_widget.dart';


class HomeView extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const HomeView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final nombre = authState is AuthAuthenticated
        ? authState.usuario.nombre
        : 'Usuario';
    final hora = DateTime.now().hour;
    final saludo = hora < 12
        ? 'Buenos días'
        : hora < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go('/login');
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        drawer: AppDrawer(nombre: nombre),
        body: CustomScrollView(
          slivers: [
            // ── SliverAppBar ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              actions: [
                BlocBuilder<NotificacionBloc, NotificacionState>(
                  builder: (context, state) {
                    final noLeidas = state is NotificacionCargada
                        ? state.noLeidas
                        : 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded),
                          onPressed: () => context.push('/notificaciones'),
                        ),
                        if (noLeidas > 0)
                          Positioned(
                            right: 8, top: 8,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  noLeidas > 9 ? '9+' : '$noLeidas',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF2D2D5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Text('$saludo,',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16)),
                          Text(nombre,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('¿Necesitas asistencia vehicular?',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Botón emergencia ───────────────────────
                    BotonEmergencia(),
                    const SizedBox(height: 24),

                    // ── Emergencia activa ──────────────────────
                    BlocBuilder<IncidenteBloc, IncidenteState>(
                      builder: (context, state) {
                        if (state is IncidenteListaCargada) {
                          final activo = state.incidentes.where((i) =>
                              i.estado != 'resuelto' &&
                              i.estado != 'cancelado').firstOrNull;
                          if (activo != null) {
                            return Column(
                              children: [
                                EmergenciaActivaCard(incidente: activo),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                        }
                        return const SizedBox();
                      },
                    ),

                    // ── Acceso rápido ──────────────────────────
                    const Text('Acceso rápido',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        AccesoRapidoCard(
                          icono: Icons.history_rounded,
                          label: 'Historial',
                          color: const Color(0xFF3B82F6),
                          onTap: () => context.push('/incidentes'),
                        ),
                        const SizedBox(width: 12),
                        AccesoRapidoCard(
                          icono: Icons.directions_car_rounded,
                          label: 'Vehículos',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push('/vehiculos'),
                        ),
                        const SizedBox(width: 12),
                        AccesoRapidoCard(
                          icono: Icons.payment_rounded,
                          label: 'Pagos',
                          color: const Color(0xFF22C55E),
                          onTap: () => context.push('/pagos'),
                        ),
                        const SizedBox(width: 12),
                        AccesoRapidoCard(
                          icono: Icons.map_rounded,
                          label: 'Ver mapa',
                          color: const Color(0xFF10B981),
                          onTap: () => context.push('/mapa'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Últimos incidentes ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Últimas emergencias',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.textPrimary)),
                        TextButton(
                          onPressed: () => context.push('/incidentes'),
                          child: const Text('Ver todo',
                              style: TextStyle(color: AppTheme.accent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<IncidenteBloc, IncidenteState>(
                      builder: (context, state) {
                        if (state is IncidenteLoading) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.accent));
                        }
                        if (state is IncidenteListaCargada) {
                          if (state.incidentes.isEmpty) {
                            return SinIncidentes();
                          }
                          final ultimos = state.incidentes.take(3).toList();
                          return Column(
                            children: ultimos
                                .map((i) => IncidenteResumenCard(incidente: i))
                                .toList(),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}