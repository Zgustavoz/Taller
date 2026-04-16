import 'package:equatable/equatable.dart';
import '../../domain/entities/incidente_entity.dart';
import '../../data/models/tipo_incidente_model.dart';

abstract class IncidenteState extends Equatable {
  const IncidenteState();
  @override
  List<Object?> get props => [];
}

class IncidenteInitial extends IncidenteState {}
class IncidenteLoading extends IncidenteState {}

class IncidenteListaCargada extends IncidenteState {
  final List<IncidenteEntity> incidentes;
  final List<TipoIncidenteModel> tipos;
  const IncidenteListaCargada(this.incidentes, this.tipos);
  @override
  List<Object?> get props => [incidentes];
}

class IncidenteDetalleCargado extends IncidenteState {
  final IncidenteEntity incidente;
  const IncidenteDetalleCargado(this.incidente);
  @override
  List<Object?> get props => [incidente];
}

class IncidenteCreadoExito extends IncidenteState {
  final IncidenteEntity incidente;
  const IncidenteCreadoExito(this.incidente);
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