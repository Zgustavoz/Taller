import 'package:equatable/equatable.dart';

abstract class NotificacionEvent extends Equatable {
  const NotificacionEvent();
  @override
  List<Object?> get props => [];
}

class NotificacionCargar extends NotificacionEvent {}

class NotificacionCargarNoLeidas extends NotificacionEvent {}

class NotificacionMarcarLeida extends NotificacionEvent {
  final int id;
  const NotificacionMarcarLeida(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificacionMarcarTodasLeidas extends NotificacionEvent {}

class NotificacionContarNoLeidas extends NotificacionEvent {}