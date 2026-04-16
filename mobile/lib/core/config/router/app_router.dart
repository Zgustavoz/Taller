import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/register_screen.dart';
import '../../../features/auth/presentation/screens/home_screen.dart';
import '../../../features/incidentes/presentation/screens/incidentes_list_screen.dart';
import '../../../features/incidentes/presentation/screens/crear_incidente_screen.dart';
import '../../../features/incidentes/presentation/screens/detalle_incidente_screen.dart';
import '../../../features/vehiculos/presentation/screens/vehiculos_screen.dart';
import '../../../features/incidentes/presentation/screens/mapa_screen.dart';

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
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/incidentes', builder: (_, _) => const IncidentesListScreen()),
    GoRoute(path: '/incidentes/crear', builder: (_, _) => const CrearIncidenteScreen()),
    GoRoute(path: '/mapa', builder: (_, __) => const MapaScreen()),
    GoRoute(
      path: '/incidentes/:id',
      builder: (_, state) => DetalleIncidenteScreen(
        incidenteId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(path: '/vehiculos', builder: (_, _) => const VehiculosScreen()),
  ],
);