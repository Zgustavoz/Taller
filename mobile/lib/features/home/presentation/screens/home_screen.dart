import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../incidentes/presentation/bloc/incidente_bloc.dart';
import '../../../incidentes/presentation/bloc/incidente_event.dart';

import '../../../notificaciones/presentation/bloc/notificacion_bloc.dart';
import '../../../notificaciones/presentation/bloc/notificacion_event.dart';

import '../widgets/home_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              IncidenteBloc()
                ..add(IncidenteCargarMios()),
        ),
        BlocProvider(
          create: (_) =>
              NotificacionBloc()
                ..add(NotificacionContarNoLeidas()),
        ),
      ],
      child: const HomeView(),
    );
  }
}