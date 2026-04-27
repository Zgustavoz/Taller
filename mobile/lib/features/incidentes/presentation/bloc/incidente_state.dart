import 'package:equatable/equatable.dart';
import '../../domain/entities/incidente_entity.dart';
import '../../data/models/tipo_incidente_model.dart';
import '../../data/models/taller_cercano_model.dart';

abstract class IncidenteState extends Equatable {
  const IncidenteState();
  @override
  List<Object?> get props => [];
}

class IncidenteInitial extends IncidenteState {}

class IncidenteLoading extends IncidenteState {}

// Estado especial mientras Gemini analiza
class IncidenteAnalizando extends IncidenteState {
  final String mensaje;
  const IncidenteAnalizando(
      {this.mensaje = 'Analizando con IA, por favor espera...'});
  @override
  List<Object?> get props => [mensaje];
}

class IncidenteListaCargada extends IncidenteState {
  final List<IncidenteEntity> incidentes;
  final List<TipoIncidenteModel> tipos;
  const IncidenteListaCargada(this.incidentes, this.tipos);
  @override
  List<Object?> get props => [incidentes];
}

class IncidenteDetalleCargado extends IncidenteState {
  final IncidenteEntity incidente;
  final List<TallerCercanoModel> talleresCercanos;
  const IncidenteDetalleCargado(this.incidente,
      {this.talleresCercanos = const []});
  @override
  List<Object?> get props => [incidente];
}

class IncidenteCreadoExito extends IncidenteState {
  final IncidenteEntity incidente;
  final int talleresNotificados;
  const IncidenteCreadoExito(this.incidente, {this.talleresNotificados = 0});
  @override
  List<Object?> get props => [incidente];
}

class IncidenteArchivosSubidos extends IncidenteState {}

class IncidenteError extends IncidenteState {
  final String mensaje;
  const IncidenteError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

class IncidenteCanceladoExito extends IncidenteState {}
class IncidenteCalificadoExito extends IncidenteState {
  final double nuevoPromedio;
  const IncidenteCalificadoExito(this.nuevoPromedio);
  @override
  List<Object?> get props => [nuevoPromedio];
}