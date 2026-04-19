import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapaWidgetEstatico extends StatefulWidget {
  final double? latitudInicial;
  final double? longitudInicial;
  final double zoom;
  final void Function(MapboxMap map)? onMapCreado;
  final void Function(double lat, double lng)? onTap;
  final List<MapaTaller> talleres;

  const MapaWidgetEstatico({
    super.key,
    this.latitudInicial,
    this.longitudInicial,
    this.zoom = 14.0,
    this.onMapCreado,
    this.onTap,
    this.talleres = const [],
  });

  @override
  State<MapaWidgetEstatico> createState() => _MapaWidgetEstaticoState();
}

class _MapaWidgetEstaticoState extends State<MapaWidgetEstatico> {
  MapboxMap? _map;
  bool _listo = false;
  bool _disposed = false;  // ← guard contra dispose prematuro

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN'] ?? '');
  }

  @override
  void didUpdateWidget(MapaWidgetEstatico old) {
    super.didUpdateWidget(old);
    if (!_disposed && old.talleres != widget.talleres && _listo) {
      _agregarMarcadoresTalleres();
    }
  }

  Future<void> _onMapCreado(MapboxMap map) async {
    if (_disposed) return;
    _map = map;

    try {
      await map.gestures.updateSettings(GesturesSettings(
        pinchToZoomEnabled: true,
        rotateEnabled: true,
        scrollEnabled: true,
        doubleTapToZoomInEnabled: true,
        doubleTouchToZoomOutEnabled: true,
        quickZoomEnabled: true,
        pitchEnabled: true,
      ));

      await map.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ));

      if (_disposed) return;
      _listo = true;

      if (widget.latitudInicial != null) {
        await map.flyTo(
          CameraOptions(
            center: Point(
                coordinates:
                    Position(widget.longitudInicial!, widget.latitudInicial!)),
            zoom: widget.zoom,
          ),
          MapAnimationOptions(duration: 800),
        );
      }

      if (_disposed) return;
      await _agregarMarcadoresTalleres();
      widget.onMapCreado?.call(map);
    } catch (e) {
      debugPrint('MapaWidget error: $e');
    }
  }

  Future<void> _agregarMarcadoresTalleres() async {
    if (_disposed || _map == null || widget.talleres.isEmpty) return;
    try {
      final annotationManager =
          await _map!.annotations.createPointAnnotationManager();
      await annotationManager.deleteAll();

      for (final taller in widget.talleres) {
        if (taller.latitud == null || taller.longitud == null) continue;
        if (_disposed) return;

        await annotationManager.create(PointAnnotationOptions(
          geometry:
              Point(coordinates: Position(taller.longitud!, taller.latitud!)),
          iconSize: 1.3,
          iconColor: taller.disponible ? 0xFF10B981 : 0xFF6B7280,
          textField: '🔧 ${taller.nombre}',
          textSize: 11,
          textOffset: [0.0, 1.8],
          textColor: 0xFF1A1A2E,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 1.0,
        ));
      }
    } catch (e) {
      debugPrint('Error marcadores: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: widget.key ?? const ValueKey('mapa_estatico'),
      onMapCreated: _onMapCreado,
      onTapListener: (MapContentGestureContext ctx) {
        if (_disposed) return;
        final lat = ctx.point.coordinates.lat.toDouble();
        final lng = ctx.point.coordinates.lng.toDouble();
        widget.onTap?.call(lat, lng);
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    // NO llamar _map?.dispose() — Mapbox lo maneja internamente
    // Llamarlo manualmente causa el crash "Image is already closed"
    _map = null;
    super.dispose();
  }
}

class MapaTaller {
  final int id;
  final String nombre;
  final double? latitud;
  final double? longitud;
  final bool disponible;

  const MapaTaller({
    required this.id,
    required this.nombre,
    this.latitud,
    this.longitud,
    required this.disponible,
  });
}