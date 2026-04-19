import 'package:equatable/equatable.dart';
import '../../domain/entities/notificacion_entity.dart';

abstract class NotificacionState extends Equatable {
  const NotificacionState();
  @override
  List<Object?> get props => [];
}

class NotificacionInitial extends NotificacionState {}
class NotificacionLoading extends NotificacionState {}

class NotificacionCargada extends NotificacionState {
  final List<NotificacionEntity> notificaciones;
  final int noLeidas;
  const NotificacionCargada(this.notificaciones, {this.noLeidas = 0});
  @override
  List<Object?> get props => [notificaciones, noLeidas];
}

class NotificacionError extends NotificacionState {
  final String mensaje;
  const NotificacionError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}