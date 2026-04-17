import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../../incidentes/presentation/bloc/incidente_bloc.dart';
import '../../../incidentes/presentation/bloc/incidente_event.dart';
import '../../../incidentes/presentation/bloc/incidente_state.dart';
import '../../../incidentes/domain/entities/incidente_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => IncidenteBloc()..add(IncidenteCargarMios())),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

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
        drawer: _AppDrawer(nombre: nombre),
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
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {},
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
                    _BotonEmergencia(),
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
                                _EmergenciaActivaCard(incidente: activo),
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
                        _AccesoRapidoCard(
                          icono: Icons.history_rounded,
                          label: 'Historial',
                          color: const Color(0xFF3B82F6),
                          onTap: () => context.push('/incidentes'),
                        ),
                        const SizedBox(width: 12),
                        _AccesoRapidoCard(
                          icono: Icons.directions_car_rounded,
                          label: 'Vehículos',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push('/vehiculos'),
                        ),
                        const SizedBox(width: 12),
                        _AccesoRapidoCard(
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
                            return _SinIncidentes();
                          }
                          final ultimos = state.incidentes.take(3).toList();
                          return Column(
                            children: ultimos
                                .map((i) => _IncidenteResumenCard(incidente: i))
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

// ─── Botón reportar emergencia ─────────────────────────────────

class _BotonEmergencia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/incidentes/crear'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.emergency_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reportar Emergencia',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Conecta con talleres cercanos',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Emergencia activa ─────────────────────────────────────────

class _EmergenciaActivaCard extends StatelessWidget {
  final IncidenteEntity incidente;
  const _EmergenciaActivaCard({required this.incidente});

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

// ─── Acceso rápido card ────────────────────────────────────────

class _AccesoRapidoCard extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccesoRapidoCard(
      {required this.icono,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Incidente resumen card ────────────────────────────────────

class _IncidenteResumenCard extends StatelessWidget {
  final IncidenteEntity incidente;
  const _IncidenteResumenCard({required this.incidente});

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

class _SinIncidentes extends StatelessWidget {
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

// ─── Drawer lateral ────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final String nombre;
  const _AppDrawer({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final correo = authState is AuthAuthenticated
        ? authState.usuario.correo
        : '';

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, Color(0xFF2D2D5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.2),
                  backgroundImage: authState is AuthAuthenticated &&
                          authState.usuario.url != null &&
                          authState.usuario.url!.isNotEmpty
                      ? NetworkImage(authState.usuario.url!)
                      : null,
                  child: authState is AuthAuthenticated &&
                          authState.usuario.url != null &&
                          authState.usuario.url!.isNotEmpty
                      ? null
                      : Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
                Text(nombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(correo,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13)),
              ],
            ),
          ),

          // Opciones
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icono: Icons.home_rounded,
                  label: 'Inicio',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icono: Icons.person_rounded,
                  label: 'Mi perfil',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/perfil');
                  },
                ),
                _DrawerItem(
                  icono: Icons.directions_car_rounded,
                  label: 'Mis vehículos',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/vehiculos');
                  },
                ),
                _DrawerItem(
                  icono: Icons.history_rounded,
                  label: 'Historial de emergencias',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/incidentes');
                  },
                ),
                _DrawerItem(
                  icono: Icons.map_rounded,
                  label: 'Ver mapa',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/mapa');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _DrawerItem(
                  icono: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('v1.0.0',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icono;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerItem(
      {required this.icono,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: color ?? AppTheme.textPrimary, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      horizontalTitleGap: 8,
      onTap: onTap,
    );
  }
}