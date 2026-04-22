import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/theme/app_theme.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';


// ─── Drawer lateral ────────────────────────────────────────────

class AppDrawer extends StatelessWidget {
  final String nombre;
  const AppDrawer({super.key, required this.nombre});

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
                DrawerItem(
                  icono: Icons.home_rounded,
                  label: 'Inicio',
                  onTap: () => Navigator.pop(context),
                ),
                DrawerItem(
                  icono: Icons.person_rounded,
                  label: 'Mi perfil',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/perfil');
                  },
                ),
                DrawerItem(
                  icono: Icons.directions_car_rounded,
                  label: 'Mis vehículos',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/vehiculos');
                  },
                ),
                DrawerItem(
                  icono: Icons.history_rounded,
                  label: 'Historial de emergencias',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/incidentes');
                  },
                ),
                DrawerItem(
                  icono: Icons.payment_rounded,
                  label: 'Pagos',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/pagos');
                  },
                ),
                DrawerItem(
                  icono: Icons.map_rounded,
                  label: 'Ver mapa',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/mapa');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                DrawerItem(
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

class DrawerItem extends StatelessWidget {
  final IconData icono;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const DrawerItem(
      {super.key, required this.icono,
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