import 'dart:typed_data';
import 'dart:ui' as ui;
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
  final MapaTecnico? tecnico; // ← técnico en ruta (opcional)

  const MapaWidgetEstatico({
    super.key,
    this.latitudInicial,
    this.longitudInicial,
    this.zoom = 14.0,
    this.onMapCreado,
    this.onTap,
    this.talleres = const [],
    this.tecnico,
  });

  @override
  State<MapaWidgetEstatico> createState() => _MapaWidgetEstaticoState();
}

class _MapaWidgetEstaticoState extends State<MapaWidgetEstatico> {
  MapboxMap? _map;
  bool _listo = false;
  bool _disposed = false;
  PointAnnotationManager? _tallerManager;
  PointAnnotationManager? _tecnicoManager;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN'] ?? '');
  }

  @override
  void didUpdateWidget(MapaWidgetEstatico old) {
    super.didUpdateWidget(old);
    if (!_disposed && _listo) {
      if (old.talleres != widget.talleres) {
        _agregarMarcadoresTalleres();
      }
      // Actualizar marcador del técnico si cambió su posición
      if (old.tecnico?.latitud != widget.tecnico?.latitud ||
          old.tecnico?.longitud != widget.tecnico?.longitud) {
        _actualizarMarcadorTecnico();
      }
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
                coordinates: Position(
                    widget.longitudInicial!, widget.latitudInicial!)),
            zoom: widget.zoom,
          ),
          MapAnimationOptions(duration: 800),
        );
      }

      if (_disposed) return;

      // Crear managers separados para talleres y técnico
      _tallerManager = await map.annotations.createPointAnnotationManager();
      _tecnicoManager = await map.annotations.createPointAnnotationManager();

      await _agregarMarcadoresTalleres();
      await _actualizarMarcadorTecnico();

      widget.onMapCreado?.call(map);
    } catch (e) {
      debugPrint('MapaWidget error: $e');
    }
  }

  // ── Generar imagen de marcador con emoji + texto ──────────────
  Future<Uint8List> _generarIcono({
    required String emoji,
    required String label,
    required Color color,
  }) async {
    const size = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fondo circular
    final bgPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(const Offset(size / 2, size / 2 - 10), 36, bgPaint);
    canvas.drawCircle(const Offset(size / 2, size / 2 - 10), 36, borderPaint);

    // Sombra debajo del círculo
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
        const Offset(size / 2, size / 2 - 6), 36, shadowPaint);

    // Punta del pin
    final path = Path();
    path.moveTo(size / 2 - 8, size / 2 + 24);
    path.lineTo(size / 2 + 8, size / 2 + 24);
    path.lineTo(size / 2, size / 2 + 42);
    path.close();
    canvas.drawPath(path, bgPaint);
    canvas.drawPath(path, borderPaint);

    // Emoji
    final emojiPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    );
    emojiPainter.layout();
    emojiPainter.paint(
      canvas,
      Offset(
        size / 2 - emojiPainter.width / 2,
        size / 2 - 10 - emojiPainter.height / 2,
      ),
    );

    // Etiqueta de texto debajo del pin
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label.length > 12 ? '${label.substring(0, 12)}...' : label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 3),
            Shadow(color: Colors.white, blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout(maxWidth: size);
    labelPainter.paint(
      canvas,
      Offset(size / 2 - labelPainter.width / 2, size / 2 + 46),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), (size + 20).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // ── Marcadores de talleres ────────────────────────────────────
  Future<void> _agregarMarcadoresTalleres() async {
    if (_disposed || _map == null || _tallerManager == null) return;
    try {
      await _tallerManager!.deleteAll();

      for (final taller in widget.talleres) {
        if (taller.latitud == null || taller.longitud == null) continue;
        if (_disposed) return;

        final icono = await _generarIcono(
          emoji: '🔧',
          label: taller.nombre,
          color: taller.disponible
              ? const Color(0xFF10B981)
              : Colors.grey.shade500,
        );

        await _tallerManager!.create(PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(taller.longitud!, taller.latitud!)),
          image: icono,
          iconSize: 0.7,
        ));
      }
    } catch (e) {
      debugPrint('Error marcadores talleres: $e');
    }
  }

  // ── Marcador del técnico en ruta ──────────────────────────────
  Future<void> _actualizarMarcadorTecnico() async {
    if (_disposed || _map == null || _tecnicoManager == null) return;
    try {
      await _tecnicoManager!.deleteAll();

      final tec = widget.tecnico;
      if (tec == null || tec.latitud == null || tec.longitud == null) return;

      final icono = await _generarIcono(
        emoji: '🚗',
        label: tec.nombre,
        color: const Color(0xFF3B82F6), // azul para el técnico
      );

      await _tecnicoManager!.create(PointAnnotationOptions(
        geometry:
            Point(coordinates: Position(tec.longitud!, tec.latitud!)),
        image: icono,
        iconSize: 0.8,
      ));
    } catch (e) {
      debugPrint('Error marcador técnico: $e');
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
    _map = null;
    _tallerManager = null;
    _tecnicoManager = null;
    super.dispose();
  }
}

// ─── Modelos de datos para el mapa ────────────────────────────

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

class MapaTecnico {
  final int id;
  final String nombre;
  final double? latitud;
  final double? longitud;

  const MapaTecnico({
    required this.id,
    required this.nombre,
    this.latitud,
    this.longitud,
  });
}