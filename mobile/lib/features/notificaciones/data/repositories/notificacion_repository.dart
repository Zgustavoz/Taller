import '../datasource/notificacion_datasource.dart';
import '../models/notificacion_model.dart';

class NotificacionRepository {
  final _ds = NotificacionDatasource();

  Future<List<NotificacionModel>> misNotificaciones(
          {bool soloNoLeidas = false}) =>
      _ds.misNotificaciones(soloNoLeidas: soloNoLeidas);

  Future<int> contarNoLeidas() => _ds.contarNoLeidas();
  Future<void> marcarLeida(int id) => _ds.marcarLeida(id);
  Future<void> marcarTodasLeidas() => _ds.marcarTodasLeidas();
}