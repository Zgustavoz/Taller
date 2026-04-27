import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/config/router/app_router.dart';
import 'core/config/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/incidentes/presentation/bloc/incidente_bloc.dart';
import 'features/vehiculos/presentation/bloc/vehiculo_bloc.dart';
import 'features/notificaciones/presentation/bloc/notificacion_bloc.dart';
import 'features/notificaciones/presentation/bloc/notificacion_event.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Para mostrar notificación en foreground en Android:
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Inicializar Firebase Messaging
  await FirebaseMessagingService().init();
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  
  runApp(const MyApp());
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AuthCheckRequested())),
        BlocProvider(create: (_) => IncidenteBloc()),
        BlocProvider(create: (_) => VehiculoBloc()),
        BlocProvider(create: (_) => NotificacionBloc()..add(NotificacionContarNoLeidas()),),

      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Sistema de Información',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}