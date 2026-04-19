import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/register_screen.dart';
import '../../../features/auth/presentation/screens/home_screen.dart';
import '../../../features/auth/presentation/screens/perfil_screen.dart';
import '../../../features/incidentes/presentation/screens/incidentes_list_screen.dart';
import '../../../features/incidentes/presentation/screens/crear_incidente_screen.dart';
import '../../../features/incidentes/presentation/screens/detalle_incidente_screen.dart';
import '../../../features/vehiculos/presentation/screens/vehiculos_screen.dart';
import '../../../features/vehiculos/presentation/screens/agregar_vehiculo_screen.dart';
import '../../../features/incidentes/presentation/screens/mapa_screen.dart';
import '../../../features/notificaciones/presentation/screens/notificaciones_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState is AuthAuthenticated;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    if (!isAuthenticated && !isAuthRoute) return '/login';
    if (isAuthenticated && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/perfil', builder: (_, __) => const PerfilScreen()),
    GoRoute(path: '/incidentes', builder: (_, __) => const IncidentesListScreen()),
    GoRoute(path: '/incidentes/crear', builder: (_, __) => const CrearIncidenteScreen()),
    GoRoute(
      path: '/incidentes/:id',
      builder: (_, state) => DetalleIncidenteScreen(
        incidenteId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/mapa',
      builder: (_, state) {
        // Lee el query param incidente_id si viene desde detalle de incidente
        final idStr = state.uri.queryParameters['incidente_id'];
        final id = idStr != null ? int.tryParse(idStr) : null;
        return MapaScreen(incidenteId: id);
      },
    ),
    GoRoute(path: '/vehiculos', builder: (_, __) => const VehiculosScreen()),
    GoRoute(path: '/vehiculos/agregar', builder: (_, __) => const AgregarVehiculoScreen()),
    GoRoute(path: '/notificaciones', builder: (_, __) => const NotificacionesScreen()),
  ],
);