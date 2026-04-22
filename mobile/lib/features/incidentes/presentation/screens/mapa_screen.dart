import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide LocationSettings;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/common/widgets/mapa_widget_estatico.dart';
import '../../data/models/taller_cercano_model.dart';

class MapaScreen extends StatefulWidget {
  final int? incidenteId;
  const MapaScreen({super.key, this.incidenteId});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  MapboxMap? _mapboxMap;
  double? _latitud;
  double? _longitud;
  bool _cargando = true;
  bool _cargandoTalleres = false;
  bool _siguiendo = true;
  List<TallerCercanoModel> _talleres = [];
  TallerCercanoModel? _tallerSeleccionado;
  int _estiloIndex = 0;

  // ── Técnico en tiempo real ────────────────────────────────────
  MapaTecnico? _tecnico;
  Timer? _pollingTimer;
  bool _tecnicoEnRuta = false;

  final _estilos = [
    {'nombre': 'Calles', 'url': MapboxStyles.MAPBOX_STREETS},
    {'nombre': 'Satélite', 'url': MapboxStyles.SATELLITE_STREETS},
    {'nombre': 'Oscuro', 'url': MapboxStyles.DARK},
  ];

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN'] ?? '');
    _inicializar();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await _obtenerUbicacion();
    if (widget.incidenteId != null) {
      await _cargarTalleresPorIncidente(widget.incidenteId!);
      // Iniciar polling del técnico si hay incidente
      _iniciarPollingTecnico();
    } else if (_latitud != null) {
      await _cargarTalleresPorUbicacion();
    }
  }

  Future<void> _obtenerUbicacion() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _latitud = pos.latitude;
          _longitud = pos.longitude;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarTalleresPorIncidente(int id) async {
    if (mounted) setState(() => _cargandoTalleres = true);
    try {
      final res = await ApiClient.instance.client
          .get('/incidentes/$id/talleres-cercanos');
      final lista = res.data['talleres'] as List;
      if (mounted) {
        setState(() {
          _talleres =
              lista.map((t) => TallerCercanoModel.fromJson(t)).toList();
          _cargandoTalleres = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoTalleres = false);
    }
  }

  Future<void> _cargarTalleresPorUbicacion() async {
    if (_latitud == null || _longitud == null) return;
    if (mounted) setState(() => _cargandoTalleres = true);
    try {
      final res = await ApiClient.instance.client.get(
        '/talleres/cercanos',
        queryParameters: {'lat': _latitud, 'lng': _longitud, 'radio_km': 15.0},
      );
      final lista = res.data['talleres'] as List;
      if (mounted) {
        setState(() {
          _talleres =
              lista.map((t) => TallerCercanoModel.fromJson(t)).toList();
          _cargandoTalleres = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoTalleres = false);
    }
  }

  // ── Polling del técnico cada 5 segundos ───────────────────────
  void _iniciarPollingTecnico() {
    // Primera consulta inmediata
    _consultarUbicacionTecnico();
    // Luego cada 5 segundos
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _consultarUbicacionTecnico(),
    );
  }

  Future<void> _consultarUbicacionTecnico() async {
    if (widget.incidenteId == null || !mounted) return;
    try {
      final res = await ApiClient.instance.client.get(
        '/tecnicos/ubicacion-incidente/${widget.incidenteId}',
      );
      final data = res.data as Map<String, dynamic>;
      final tieneTecnico = data['tiene_tecnico'] == true;
      final lat = (data['latitud'] as num?)?.toDouble();
      final lng = (data['longitud'] as num?)?.toDouble();

      if (!mounted) return;

      if (tieneTecnico && lat != null && lng != null) {
        setState(() {
          _tecnicoEnRuta = true;
          _tecnico = MapaTecnico(
            id: data['tecnico_id'] ?? 0,
            nombre: data['nombre'] ?? 'Técnico',
            latitud: lat,
            longitud: lng,
          );
        });
      } else {
        setState(() {
          _tecnicoEnRuta = tieneTecnico;
          _tecnico = null;
        });
      }
    } catch (_) {
      // Silencioso — no romper la UI si falla el polling
    }
  }

  void _centrar() {
    if (_mapboxMap == null || _latitud == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_longitud!, _latitud!)),
        zoom: 14.0,
        pitch: 30,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  // ── Centrar en el técnico ─────────────────────────────────────
  void _centrarEnTecnico() {
    if (_mapboxMap == null || _tecnico?.latitud == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
            coordinates: Position(_tecnico!.longitud!, _tecnico!.latitud!)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  List<MapaTaller> get _marcadoresTalleres => _talleres
      .where((t) => t.latitud != null && t.longitud != null)
      .map((t) => MapaTaller(
            id: t.id,
            nombre: t.nombre,
            latitud: t.latitud,
            longitud: t.longitud,
            disponible: t.estaDisponible,
          ))
      .toList();

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
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.incidenteId != null
                ? 'Talleres del incidente'
                : 'Talleres cercanos',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              final next = (_estiloIndex + 1) % _estilos.length;
              setState(() => _estiloIndex = next);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.layers_rounded, size: 16),
                const SizedBox(width: 4),
                Text(_estilos[_estiloIndex]['nombre']!,
                    style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
      body: Stack(children: [

        // ── Mapa con talleres y técnico ───────────────────
        _cargando
            ? Container(
                color: AppTheme.primary,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Obteniendo ubicación...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              )
            : MapaWidgetEstatico(
                key: const ValueKey('mapa_pantalla_completa'),
                latitudInicial: _latitud,
                longitudInicial: _longitud,
                zoom: 14.0,
                talleres: _marcadoresTalleres,
                tecnico: _tecnico, // ← técnico en tiempo real
                onMapCreado: (map) => _mapboxMap = map,
                onTap: (lat, lng) {},
              ),

        // ── Badge técnico en ruta ─────────────────────────
        if (_tecnicoEnRuta)
          Positioned(
            top: 100, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _centrarEnTecnico,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF3B82F6)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🚗', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      _tecnico != null
                          ? '${_tecnico!.nombre} en camino'
                          : 'Técnico asignado',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.my_location_rounded,
                        color: Colors.white, size: 14),
                  ]),
                ),
              ),
            ),
          ),

        // ── Indicador cargando talleres ───────────────────
        if (_cargandoTalleres)
          Positioned(
            top: _tecnicoEnRuta ? 150 : 100,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8)
                  ],
                ),
                child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accent),
                      ),
                      SizedBox(width: 8),
                      Text('Buscando talleres...',
                          style: TextStyle(fontSize: 12)),
                    ]),
              ),
            ),
          ),

        // ── Panel inferior ────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                const SizedBox(height: 10),
                Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),

                // Info ubicación + conteo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppTheme.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tu ubicación',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary)),
                          Text(
                            _latitud != null
                                ? '${_latitud!.toStringAsFixed(4)}, ${_longitud!.toStringAsFixed(4)}'
                                : 'Obteniendo...',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_talleres.length} talleres',
                        style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // Lista horizontal de talleres
                if (_talleres.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _talleres.length,
                      itemBuilder: (_, i) {
                        final t = _talleres[i];
                        final sel = _tallerSeleccionado?.id == t.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() =>
                                _tallerSeleccionado = sel ? null : t);
                            if (!sel && t.latitud != null) {
                              _mapboxMap?.flyTo(
                                CameraOptions(
                                  center: Point(
                                      coordinates: Position(
                                          t.longitud!, t.latitud!)),
                                  zoom: 16,
                                ),
                                MapAnimationOptions(duration: 600),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 170,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.accent
                                      .withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.accent
                                    : Colors.grey.shade200,
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.build_rounded,
                                      color: sel
                                          ? AppTheme.accent
                                          : Colors.grey,
                                      size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      t.nombre,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: sel
                                              ? AppTheme.accent
                                              : AppTheme.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12,
                                      color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 3),
                                  Text(
                                      t.calificacion.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 11)),
                                  const Spacer(),
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                        color: t.estaDisponible
                                            ? const Color(0xFF10B981)
                                            : Colors.grey,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.estaDisponible
                                        ? 'Libre'
                                        : 'Ocupado',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: t.estaDisponible
                                            ? const Color(0xFF10B981)
                                            : Colors.grey),
                                  ),
                                ]),
                                if (t.especialidades.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    t.especialidades.first,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (t.telefono != null) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.phone_rounded,
                                        size: 10, color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Text(t.telefono!,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                Colors.grey.shade500)),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else if (!_cargandoTalleres) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      'No hay talleres disponibles en el área',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Botones flotantes ────────────────────────────
        Positioned(
          right: 16,
          bottom: _talleres.isEmpty ? 140 : 210,
          child: Column(children: [
            // Botón centrar en técnico (solo si está en ruta)
            if (_tecnico != null) ...[
              _BtnFlotante(
                icono: Icons.directions_car_rounded,
                color: const Color(0xFF3B82F6),
                onTap: _centrarEnTecnico,
              ),
              const SizedBox(height: 10),
            ],
            _BtnFlotante(
              icono: _siguiendo
                  ? Icons.gps_fixed_rounded
                  : Icons.gps_not_fixed_rounded,
              color:
                  _siguiendo ? AppTheme.accent : Colors.grey.shade600,
              onTap: () {
                setState(() => _siguiendo = true);
                _centrar();
              },
            ),
            const SizedBox(height: 10),
            _BtnFlotante(
              icono: Icons.add_rounded,
              color: AppTheme.primary,
              onTap: () async {
                final cam = await _mapboxMap?.getCameraState();
                if (cam != null) {
                  _mapboxMap?.flyTo(
                      CameraOptions(zoom: cam.zoom + 1),
                      MapAnimationOptions(duration: 300));
                }
              },
            ),
            const SizedBox(height: 10),
            _BtnFlotante(
              icono: Icons.remove_rounded,
              color: AppTheme.primary,
              onTap: () async {
                final cam = await _mapboxMap?.getCameraState();
                if (cam != null) {
                  _mapboxMap?.flyTo(
                      CameraOptions(zoom: cam.zoom - 1),
                      MapAnimationOptions(duration: 300));
                }
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

class _BtnFlotante extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;
  const _BtnFlotante(
      {required this.icono, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
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
    );
  }
}