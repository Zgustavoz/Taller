import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide LocationSettings;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/config/theme/app_theme.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  MapboxMap? _mapboxMap;
  double? _latitud;
  double? _longitud;
  bool _cargando = true;
  bool _siguiendoUbicacion = true;

  // Estilos de mapa disponibles
  final List<Map<String, dynamic>> _estilos = [
    {'nombre': 'Calles', 'url': MapboxStyles.MAPBOX_STREETS},
    {'nombre': 'Satélite', 'url': MapboxStyles.SATELLITE_STREETS},
    {'nombre': 'Oscuro', 'url': MapboxStyles.DARK},
    {'nombre': 'Claro', 'url': MapboxStyles.LIGHT},
  ];
  int _estiloActual = 0;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN'] ?? '');
    _obtenerUbicacion();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitud = pos.latitude;
        _longitud = pos.longitude;
        _cargando = false;
      });
      _centrarEnUbicacion();
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  void _centrarEnUbicacion() {
    if (_mapboxMap == null || _latitud == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_longitud!, _latitud!)),
        zoom: 15.0,
        pitch: 45,   // perspectiva 3D
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  void _cambiarEstilo() {
    setState(() {
      _estiloActual = (_estiloActual + 1) % _estilos.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Mapa de talleres',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        centerTitle: true,
        actions: [
          // Botón cambiar estilo
          GestureDetector(
            onTap: _cambiarEstilo,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers_rounded, size: 16),
                  const SizedBox(width: 4),
                  Text(_estilos[_estiloActual]['nombre'],
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Mapa fullscreen ──────────────────────────────
          _cargando
              ? Container(
                  color: AppTheme.primary,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Cargando mapa...',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              : MapWidget(
                  styleUri: _estilos[_estiloActual]['url'],
                  onMapCreated: (map) {
                    _mapboxMap = map;

                    // Habilitar gestos: zoom pinch, rotación, inclinación
                    map.gestures.updateSettings(
                      GesturesSettings(
                        pinchToZoomEnabled: true,
                        rotateEnabled: true,
                        pitchEnabled: true,
                        doubleTapToZoomInEnabled: true,
                        doubleTouchToZoomOutEnabled: true,
                        quickZoomEnabled: true,
                        scrollEnabled: true,
                      ),
                    );

                    // Mostrar ubicación del usuario
                    map.location.updateSettings(
                      LocationComponentSettings(
                        enabled: true,
                        pulsingEnabled: true,
                        pulsingColor: AppTheme.accent.value,
                      ),
                    );

                    _centrarEnUbicacion();
                  },
                  onScrollListener: (_) {
                    // Al mover el mapa manualmente, dejar de seguir
                    if (_siguiendoUbicacion) {
                      setState(() => _siguiendoUbicacion = false);
                    }
                  },
                ),

          // ── Panel inferior info ──────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppTheme.accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tu ubicación actual',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary)),
                            Text(
                              _latitud != null
                                  ? 'Lat: ${_latitud!.toStringAsFixed(4)}  Lng: ${_longitud!.toStringAsFixed(4)}'
                                  : 'Obteniendo coordenadas...',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icono: Icons.build_rounded,
                          label: 'Talleres cercanos',
                          valor: 'Próximamente',
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoChip(
                          icono: Icons.emergency_rounded,
                          label: 'Emergencias activas',
                          valor: 'En área',
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Botones flotantes ────────────────────────────
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                // Mi ubicación
                _BtnFlotante(
                  icono: _siguiendoUbicacion
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  color: _siguiendoUbicacion
                      ? AppTheme.accent
                      : Colors.grey.shade600,
                  onTap: () {
                    setState(() => _siguiendoUbicacion = true);
                    _centrarEnUbicacion();
                  },
                  tooltip: 'Mi ubicación',
                ),
                const SizedBox(height: 10),
                // Zoom in
                _BtnFlotante(
                  icono: Icons.add_rounded,
                  color: AppTheme.primary,
                  onTap: () async {
                    final camara = await _mapboxMap?.getCameraState();
                    if (camara != null) {
                      _mapboxMap?.flyTo(
                        CameraOptions(zoom: (camara.zoom) + 1),
                        MapAnimationOptions(duration: 300),
                      );
                    }
                  },
                  tooltip: 'Acercar',
                ),
                const SizedBox(height: 10),
                // Zoom out
                _BtnFlotante(
                  icono: Icons.remove_rounded,
                  color: AppTheme.primary,
                  onTap: () async {
                    final camara = await _mapboxMap?.getCameraState();
                    if (camara != null) {
                      _mapboxMap?.flyTo(
                        CameraOptions(zoom: (camara.zoom) - 1),
                        MapAnimationOptions(duration: 300),
                      );
                    }
                  },
                  tooltip: 'Alejar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BtnFlotante extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _BtnFlotante(
      {required this.icono,
      required this.color,
      required this.onTap,
      required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icono, color: color, size: 22),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final Color color;
  const _InfoChip(
      {required this.icono,
      required this.label,
      required this.valor,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
                Text(valor,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}