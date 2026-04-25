import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:file_picker/file_picker.dart';
import 'package:mobile/features/vehiculos/data/models/vehiculo_model.dart';
import '../../../vehiculos/data/datasource/vehiculo_datasource.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide LocationSettings;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../../../core/common/widgets/mapa_widget_estatico.dart';
import '../../../../core/network/api_client.dart';
import '../bloc/incidente_bloc.dart';
import '../bloc/incidente_event.dart';
import '../bloc/incidente_state.dart';
import '../../data/models/taller_cercano_model.dart';
import '../widgets/crear/pantalla_analizando.dart';
import '../widgets/crear/media_sheet.dart';
import '../widgets/shared/widgets_compartidos.dart';

class CrearIncidenteScreen extends StatefulWidget {
  const CrearIncidenteScreen({super.key});

  @override
  State<CrearIncidenteScreen> createState() => _CrearIncidenteScreenState();
}

class _CrearIncidenteScreenState extends State<CrearIncidenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _picker = img_picker.ImagePicker();
  final _recorder = AudioRecorder();
  MapboxMap? _mapboxMap;
  double? _latitud;
  double? _longitud;
  int? _vehiculoSeleccionado;
  String? _tipoSeleccionado;
  final List<File> _archivos = [];
  bool _grabando = false;
  bool _cargandoUbicacion = true;
  List<VehiculoModel> _vehiculos = [];
  bool _cargandoVehiculos = true;
  List<MapaTaller> _talleres = [];

  final _tiposProblema = {
    'flat_tire': 'Llanta pinchada',
    'battery_dead': 'Batería descargada',
    'engine_overheat': 'Motor sobrecalentado',
    'minor_accident': 'Accidente menor',
    'electrical': 'Problema eléctrico',
    'lost_keys': 'Llaves perdidas',
    'fuel_empty': 'Sin combustible',
    'other': 'Otro problema',
  };

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN'] ?? '');
    _obtenerUbicacion();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final lista = await VehiculoDatasource().misVehiculos();
      if (mounted) setState(() { _vehiculos = lista; _cargandoVehiculos = false; });
    } catch (_) {
      if (mounted) setState(() => _cargandoVehiculos = false);
    }
  }

  List<String> _especialidadesParaTipo(String tipo) {
    const mapa = {
      'flat_tire': ['llanta'],
      'battery_dead': ['bateria', 'electrico'],
      'engine_overheat': ['motor'],
      'minor_accident': ['choque', 'carroceria'],
      'electrical': ['electrico', 'bateria'],
      'lost_keys': ['cerrajeria', 'general'],
      'fuel_empty': ['general'],
      'other': <String>[],
    };
    return mapa[tipo] ?? [];
  }

  Future<void> _cargarTalleres() async {
    if (_latitud == null || _longitud == null) return;
    try {
      final especialidades = _tipoSeleccionado != null
          ? _especialidadesParaTipo(_tipoSeleccionado!)
          : <String>[];
      final res = await ApiClient.instance.client.get(
        '/talleres/cercanos',
        queryParameters: {
          'lat': _latitud,
          'lng': _longitud,
          'radio_km': 15.0,
          if (especialidades.isNotEmpty) 'especialidades': especialidades.join(','),
        },
      );
      final lista = res.data['talleres'] as List;
      if (mounted) {
        setState(() {
          _talleres = lista
              .map((t) => TallerCercanoModel.fromJson(t))
              .where((t) => t.latitud != null && t.longitud != null)
              .map((t) => MapaTaller(
                    id: t.id,
                    nombre: t.nombre,
                    latitud: t.latitud!,
                    longitud: t.longitud!,
                    disponible: t.estaDisponible,
                  ))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _obtenerUbicacion() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _cargandoUbicacion = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() { _latitud = pos.latitude; _longitud = pos.longitude; _cargandoUbicacion = false; });
        await Future.delayed(const Duration(milliseconds: 500));
        _moverCamara();
        _cargarTalleres();
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  void _moverCamara() {
    if (_mapboxMap == null || _latitud == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: Position(_longitud!, _latitud!)), zoom: 15.0),
      MapAnimationOptions(duration: 800),
    );
  }

  Future<void> _tomarFoto() async {
    final foto = await _picker.pickImage(source: img_picker.ImageSource.camera, imageQuality: 85);
    if (foto != null) setState(() => _archivos.add(File(foto.path)));
  }

  Future<void> _pickImagenes() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) setState(() => _archivos.addAll(imgs.map((x) => File(x.path))));
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result?.files.single.path != null) setState(() => _archivos.add(File(result!.files.single.path!)));
  }

  Future<void> _toggleGrabar() async {
    FocusScope.of(context).unfocus();
    if (_grabando) {
      final path = await _recorder.stop();
      if (path != null) {
        final archivo = File(path);
        if (await archivo.exists()) setState(() => _archivos.add(archivo));
      }
      setState(() => _grabando = false);
    } else {
      if (!await _recorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso de micrófono requerido')));
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final ruta = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: ruta);
      setState(() => _grabando = true);
    }
  }

  void _mostrarOpcionesMedia() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => MediaSheet(
        onTomarFoto: () { Navigator.pop(context); _tomarFoto(); },
        onGaleria: () { Navigator.pop(context); _pickImagenes(); },
        onPickAudio: () { Navigator.pop(context); _pickAudio(); },
        onGrabarAudio: () { Navigator.pop(context); _toggleGrabar(); },
        grabando: _grabando,
      ),
    );
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    if (_latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activa el GPS para continuar')));
      return;
    }
    final descripcionCompleta = _tipoSeleccionado != null
        ? 'Tipo de problema reportado: ${_tiposProblema[_tipoSeleccionado]}.\n\n${_descripcionCtrl.text.trim()}'
        : _descripcionCtrl.text.trim();

    context.read<IncidenteBloc>().add(IncidenteCrear(
          latitud: _latitud!,
          longitud: _longitud!,
          textoDireccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
          descripcion: descripcionCompleta.isEmpty ? null : descripcionCompleta,
          tipoIncidenteId: null,
          vehiculoId: _vehiculoSeleccionado,
          nivelPrioridad: null,
          archivos: List.from(_archivos),
        ));
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _direccionCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncidenteBloc, IncidenteState>(
      listener: (context, state) {
        if (state is IncidenteCreadoExito) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Emergencia reportada · ${state.talleresNotificados} talleres notificados'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          context.push('/incidentes/${state.incidente.id}');
        }
        if (state is IncidenteError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.mensaje),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: BlocBuilder<IncidenteBloc, IncidenteState>(
        builder: (context, state) {
          if (state is IncidenteAnalizando) return PantallaAnalizando(mensaje: state.mensaje);

          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              title: const Text('Reportar Emergencia', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  // ── Tipo de problema ──────────────────────
                  Seccion(icono: Icons.warning_rounded, titulo: 'Tipo de problema'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _tipoSeleccionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Selecciona el tipo de problema'),
                    items: _tiposProblema.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) { setState(() => _tipoSeleccionado = v); _cargarTalleres(); },
                    validator: (v) => v == null ? 'Selecciona un tipo de problema' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Mapa ──────────────────────────────────
                  Seccion(icono: Icons.map_rounded, titulo: 'Ubicación'),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 220,
                      child: _cargandoUbicacion
                          ? Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: AppTheme.accent),
                                  SizedBox(height: 12),
                                  Text('Obteniendo ubicación...', style: TextStyle(color: Colors.grey)),
                                ],
                              )),
                            )
                          : Stack(children: [
                              MapaWidgetEstatico(
                                key: const ValueKey('mapa_incidente'),
                                latitudInicial: _latitud,
                                longitudInicial: _longitud,
                                zoom: 15.0,
                                talleres: _talleres,
                                onMapCreado: (map) => _mapboxMap = map,
                                onTap: (lat, lng) => setState(() { _latitud = lat; _longitud = lng; }),
                              ),
                              Positioned(
                                top: 10, right: 10,
                                child: GestureDetector(
                                  onTap: () => context.push('/mapa'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.fullscreen_rounded, size: 16, color: AppTheme.accent),
                                      SizedBox(width: 4),
                                      Text('Ver mapa', style: TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ),
                              ),
                            ]),
                    ),
                  ),
                  if (_latitud != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.gps_fixed_rounded, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 6),
                      Text('${_latitud!.toStringAsFixed(5)}, ${_longitud!.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _direccionCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Dirección o referencia (opcional)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Vehículo ──────────────────────────────────
                  Seccion(icono: Icons.directions_car_rounded, titulo: 'Vehículo'),
                  const SizedBox(height: 10),
                  _cargandoVehiculos
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                      : _vehiculos.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(children: [
                                Icon(Icons.info_outline_rounded, color: Colors.orange.shade400, size: 18),
                                const SizedBox(width: 10),
                                const Expanded(child: Text('No tienes vehículos registrados.',
                                    style: TextStyle(fontSize: 12, color: Colors.orange))),
                              ]),
                            )
                          : Column(
                              children: _vehiculos.map((v) {
                                final sel = _vehiculoSeleccionado == v.id;
                                return GestureDetector(
                                  onTap: () => setState(() => _vehiculoSeleccionado = sel ? null : v.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: sel ? AppTheme.accent.withValues(alpha: 0.08) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: sel ? AppTheme.accent : Colors.grey.shade200, width: sel ? 2 : 1),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 42, height: 42,
                                        decoration: BoxDecoration(
                                          color: sel ? AppTheme.accent.withValues(alpha: 0.15) : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          v.tipo == 'motorcycle' ? Icons.two_wheeler_rounded
                                              : v.tipo == 'truck' ? Icons.local_shipping_rounded
                                              : Icons.directions_car_rounded,
                                          color: sel ? AppTheme.accent : Colors.grey, size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('${v.marca} ${v.modelo}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                                color: sel ? AppTheme.accent : AppTheme.textPrimary)),
                                        Text('${v.placa} · ${v.year}${v.color != null ? ' · ${v.color}' : ''}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                      ])),
                                      if (sel) Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                      ),
                                    ]),
                                  ),
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 24),

                  // ── Info IA ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.psychology_rounded, color: Color(0xFF3B82F6), size: 22),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Análisis automático con IA',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3B82F6))),
                        SizedBox(height: 2),
                        Text('Gemini analizará tus fotos, audio y descripción para clasificar la emergencia.',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Descripción ───────────────────────────
                  Seccion(icono: Icons.description_rounded, titulo: 'Descripción'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe el problema... La IA analizará tu descripción',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Evidencia ─────────────────────────────
                  Seccion(
                      icono: Icons.attach_file_rounded,
                      titulo: 'Evidencia ${_archivos.isNotEmpty ? "(${_archivos.length})" : ""}'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _mostrarOpcionesMedia,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        Icon(_grabando ? Icons.stop_circle_rounded : Icons.add_a_photo_rounded,
                            color: _grabando ? AppTheme.error : AppTheme.accent, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _grabando ? '🔴 Grabando... toca para detener' : 'Foto · Audio · Grabar',
                          style: TextStyle(color: _grabando ? AppTheme.error : AppTheme.accent, fontWeight: FontWeight.w600),
                        ),
                        if (_archivos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('La IA analizará los archivos que adjuntes',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ),
                      ]),
                    ),
                  ),
                  if (_archivos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _archivos.length,
                      itemBuilder: (_, i) => ArchivoItem(
                        archivo: _archivos[i],
                        onRemover: () => setState(() => _archivos.removeAt(i)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // ── Botón enviar ──────────────────────────
                  ElevatedButton.icon(
                    onPressed: _enviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      minimumSize: const ui.Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.emergency_rounded, color: Colors.white),
                    label: const Text('Reportar Emergencia',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text('La IA analizará y notificará talleres automáticamente',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500), textAlign: TextAlign.center)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}