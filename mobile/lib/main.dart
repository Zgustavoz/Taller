import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/router/app_router.dart';
import 'core/config/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(AuthCheckRequested()),
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Sistema de Información',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}