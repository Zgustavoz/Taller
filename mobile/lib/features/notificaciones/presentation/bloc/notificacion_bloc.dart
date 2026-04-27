import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/notificacion_repository.dart';
import 'notificacion_event.dart';
import 'notificacion_state.dart';

class NotificacionBloc
    extends Bloc<NotificacionEvent, NotificacionState> {
  final _repo = NotificacionRepository();

  NotificacionBloc() : super(NotificacionInitial()) {
    on<NotificacionCargar>(_onCargar);
    on<NotificacionCargarNoLeidas>(_onCargarNoLeidas);
    on<NotificacionMarcarLeida>(_onMarcarLeida);
    on<NotificacionMarcarTodasLeidas>(_onMarcarTodas);
    on<NotificacionContarNoLeidas>(_onContar);
  }

  Future<void> _onCargar(
      NotificacionCargar e, Emitter emit) async {
    emit(NotificacionLoading());
    try {
      final notifs = await _repo.misNotificaciones();
      final noLeidas = notifs.where((n) => !n.esLeida).length;
      emit(NotificacionCargada(notifs, noLeidas: noLeidas));
    } catch (e) {
      emit(NotificacionError(e.toString()));
    }
  }

  Future<void> _onCargarNoLeidas(
      NotificacionCargarNoLeidas e, Emitter emit) async {
    emit(NotificacionLoading());
    try {
      final notifs =
          await _repo.misNotificaciones(soloNoLeidas: true);
      emit(NotificacionCargada(notifs,
          noLeidas: notifs.length));
    } catch (e) {
      emit(NotificacionError(e.toString()));
    }
  }

  Future<void> _onMarcarLeida(
      NotificacionMarcarLeida e, Emitter emit) async {
    try {
      await _repo.marcarLeida(e.id);
      final notifs = await _repo.misNotificaciones();
      final noLeidas = notifs.where((n) => !n.esLeida).length;
      emit(NotificacionCargada(notifs, noLeidas: noLeidas));
    } catch (_) {}
  }

  Future<void> _onMarcarTodas(
      NotificacionMarcarTodasLeidas e, Emitter emit) async {
    try {
      await _repo.marcarTodasLeidas();
      add(NotificacionCargar());
    } catch (_) {}
  }

  Future<void> _onContar(
      NotificacionContarNoLeidas e, Emitter emit) async {
    try {
      final total = await _repo.contarNoLeidas();
      final current = state is NotificacionCargada
          ? (state as NotificacionCargada).notificaciones
          : <dynamic>[];
      emit(NotificacionCargada(
        current.cast(),
        noLeidas: total,
      ));
    } catch (_) {}
  }
}