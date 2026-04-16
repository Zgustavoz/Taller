import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide LocationSettings;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../bloc/incidente_bloc.dart';
import '../bloc/incidente_event.dart';
import '../bloc/incidente_state.dart';
import '../../data/models/tipo_incidente_model.dart';
import '../../data/repositories/incidente_repository.dart';

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
  final _repo = IncidenteRepository();

  MapboxMap? _mapboxMap;
  double? _latitud;
  double? _longitud;
  int? _tipoSeleccionado;
  int _prioridad = 3;
  final List<File> _archivos = [];
  List<TipoIncidenteModel> _tipos = [];
  bool _grabando = false;
  String? _rutaAudio;
  bool _cargandoUbicacion = true;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN'] ?? '');
    _obtenerUbicacion();
    _cargarTipos();
  }

  Future<void> _cargarTipos() async {
    try {
      final tipos = await _repo.listarTipos();
      if (mounted) setState(() => _tipos = tipos);
    } catch (_) {}
  }

  Future<void> _obtenerUbicacion() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _cargandoUbicacion = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _latitud = pos.latitude;
          _longitud = pos.longitude;
          _cargandoUbicacion = false;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        _moverCamara();
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  void _moverCamara() {
    if (_mapboxMap == null || _latitud == null || _longitud == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_longitud!, _latitud!)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  // ── Tomar foto con cámara ──────────────────────────────────
  Future<void> _tomarFoto() async {
    final foto = await _picker.pickImage(
      source: img_picker.ImageSource.camera,
      imageQuality: 85,
    );
    if (foto != null) setState(() => _archivos.add(File(foto.path)));
  }

  // ── Galería de imágenes ────────────────────────────────────
  Future<void> _pickImagenes() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      setState(() => _archivos.addAll(imgs.map((x) => File(x.path))));
    }
  }

  // ── Video desde cámara ─────────────────────────────────────
  Future<void> _grabarVideo() async {
    final video = await _picker.pickVideo(
        source: img_picker.ImageSource.camera,
        maxDuration: const Duration(minutes: 2));
    if (video != null) setState(() => _archivos.add(File(video.path)));
  }

  // ── Video desde galería ────────────────────────────────────
  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
        source: img_picker.ImageSource.gallery);
    if (video != null) setState(() => _archivos.add(File(video.path)));
  }

  // ── Audio desde archivos ───────────────────────────────────
  Future<void> _pickAudio() async {
    final result =
        await FilePicker.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _archivos.add(File(result.files.single.path!)));
    }
  }

  // ── Grabar audio ───────────────────────────────────────────
  Future<void> _toggleGrabar() async {
    if (_grabando) {
      final path = await _recorder.stop();
      if (path != null) setState(() => _archivos.add(File(path)));
      setState(() => _grabando = false);
    } else {
      final dir = await getTemporaryDirectory();
      _rutaAudio =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: _rutaAudio!);
      setState(() => _grabando = true);
    }
  }

  void _removerArchivo(int idx) => setState(() => _archivos.removeAt(idx));

  void _mostrarOpcionesMedia() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MediaBottomSheet(
        onTomarFoto: () { Navigator.pop(context); _tomarFoto(); },
        onGaleria: () { Navigator.pop(context); _pickImagenes(); },
        onGrabarVideo: () { Navigator.pop(context); _grabarVideo(); },
        onVideoGaleria: () { Navigator.pop(context); _pickVideo(); },
        onPickAudio: () { Navigator.pop(context); _pickAudio(); },
        onGrabarAudio: () { Navigator.pop(context); _toggleGrabar(); },
        grabando: _grabando,
      ),
    );
  }

  void _enviar() {
    if (_formKey.currentState!.validate()) {
      if (_latitud == null || _longitud == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Activa el GPS para continuar')));
        return;
      }
      context.read<IncidenteBloc>().add(IncidenteCrear(
            latitud: _latitud!,
            longitud: _longitud!,
            textoDireccion: _direccionCtrl.text.trim().isEmpty
                ? null
                : _direccionCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim().isEmpty
                ? null
                : _descripcionCtrl.text.trim(),
            tipoIncidenteId: _tipoSeleccionado,
            nivelPrioridad: _prioridad,
            archivos: List.from(_archivos),
          ));
    }
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
            content: const Text('✅ Emergencia reportada'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
          context.pop();
        }
        if (state is IncidenteError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.mensaje),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          title: const Text('Reportar Emergencia',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // ── GPS / Mapa ─────────────────────────────────
              _Seccion(icono: Icons.map_rounded, titulo: 'Ubicación'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 200,
                  child: _cargandoUbicacion
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: AppTheme.accent),
                              SizedBox(height: 12),
                              Text('Obteniendo ubicación...',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          )),
                        )
                      : MapWidget(
                          onMapCreated: (map) {
                            _mapboxMap = map;
                            _moverCamara();
                          },
                          onTapListener: (MapContentGestureContext coord) {
                            setState(() {
                              _latitud = coord.point.coordinates.lat
                                  .toDouble();
                              _longitud = coord.point.coordinates.lng
                                  .toDouble();
                            });
                          },
                        ),
                ),
              ),
              if (_latitud != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.gps_fixed_rounded,
                      size: 14, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Lat: ${_latitud!.toStringAsFixed(5)}  Lng: ${_longitud!.toStringAsFixed(5)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
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

              // ── Tipo ───────────────────────────────────────
              _Seccion(icono: Icons.category_rounded, titulo: 'Tipo de incidente'),
              const SizedBox(height: 10),
              _tipos.isEmpty
                  ? Text('Cargando tipos...',
                      style: TextStyle(color: Colors.grey.shade500))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tipos.map((t) {
                        final sel = _tipoSeleccionado == t.id;
                        return GestureDetector(
                          onTap: () => setState(() =>
                              _tipoSeleccionado = sel ? null : t.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.accent : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: sel
                                      ? AppTheme.accent
                                      : Colors.grey.shade200),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: AppTheme.accent
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2))
                                    ]
                                  : [],
                            ),
                            child: Text(t.nombre,
                                style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13)),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24),

              // ── Prioridad ──────────────────────────────────
              _Seccion(icono: Icons.priority_high_rounded, titulo: 'Prioridad'),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (i) {
                  final nivel = i + 1;
                  final activo = nivel <= _prioridad;
                  return GestureDetector(
                    onTap: () => setState(() => _prioridad = nivel),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: activo
                            ? _colorPrioridad(_prioridad)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('$nivel',
                            style: TextStyle(
                                color:
                                    activo ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // ── Descripción ────────────────────────────────
              _Seccion(
                  icono: Icons.description_rounded,
                  titulo: 'Descripción'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe el problema...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // ── Evidencia ──────────────────────────────────
              _Seccion(icono: Icons.attach_file_rounded, titulo: 'Evidencia'),
              const SizedBox(height: 12),

              // Botón principal para abrir opciones
              GestureDetector(
                onTap: _mostrarOpcionesMedia,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _grabando
                            ? Icons.stop_circle_rounded
                            : Icons.add_a_photo_rounded,
                        color: _grabando ? AppTheme.error : AppTheme.accent,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _grabando
                            ? '🔴 Grabando audio... toca para detener'
                            : 'Agregar foto, video o audio',
                        style: TextStyle(
                          color: _grabando
                              ? AppTheme.error
                              : AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Grid de archivos adjuntos
              if (_archivos.isNotEmpty) ...[
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _archivos.length,
                  itemBuilder: (_, i) => _ArchivoGridItem(
                    archivo: _archivos[i],
                    onRemover: () => _removerArchivo(i),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // ── Botón enviar ───────────────────────────────
              BlocBuilder<IncidenteBloc, IncidenteState>(
                builder: (context, state) {
                  return ElevatedButton.icon(
                    onPressed:
                        state is IncidenteLoading ? null : _enviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      minimumSize: const ui.Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: state is IncidenteLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.emergency_rounded,
                            color: Colors.white),
                    label: Text(
                      state is IncidenteLoading
                          ? 'Enviando...'
                          : 'Reportar Emergencia',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorPrioridad(int p) {
    switch (p) {
      case 1: return const Color(0xFF10B981);
      case 2: return const Color(0xFF3B82F6);
      case 3: return const Color(0xFFF59E0B);
      case 4: return const Color(0xFFEC4899);
      case 5: return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }
}

// ─── Media Bottom Sheet ────────────────────────────────────────

class _MediaBottomSheet extends StatelessWidget {
  final VoidCallback onTomarFoto;
  final VoidCallback onGaleria;
  final VoidCallback onGrabarVideo;
  final VoidCallback onVideoGaleria;
  final VoidCallback onPickAudio;
  final VoidCallback onGrabarAudio;
  final bool grabando;

  const _MediaBottomSheet({
    required this.onTomarFoto,
    required this.onGaleria,
    required this.onGrabarVideo,
    required this.onVideoGaleria,
    required this.onPickAudio,
    required this.onGrabarAudio,
    required this.grabando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agregar evidencia',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
            children: [
              _MediaOpcion(
                icono: Icons.camera_alt_rounded,
                label: 'Cámara',
                color: const Color(0xFF3B82F6),
                onTap: onTomarFoto,
              ),
              _MediaOpcion(
                icono: Icons.photo_library_rounded,
                label: 'Galería',
                color: const Color(0xFF8B5CF6),
                onTap: onGaleria,
              ),
              _MediaOpcion(
                icono: Icons.videocam_rounded,
                label: 'Grabar video',
                color: const Color(0xFFEC4899),
                onTap: onGrabarVideo,
              ),
              _MediaOpcion(
                icono: Icons.video_library_rounded,
                label: 'Video galería',
                color: const Color(0xFF10B981),
                onTap: onVideoGaleria,
              ),
              _MediaOpcion(
                icono: Icons.audio_file_rounded,
                label: 'Archivo audio',
                color: const Color(0xFFF59E0B),
                onTap: onPickAudio,
              ),
              _MediaOpcion(
                icono: grabando
                    ? Icons.stop_rounded
                    : Icons.mic_rounded,
                label: grabando ? 'Detener' : 'Grabar audio',
                color: grabando ? AppTheme.error : const Color(0xFF6B7280),
                onTap: onGrabarAudio,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MediaOpcion extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MediaOpcion(
      {required this.icono,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Archivo grid item ─────────────────────────────────────────

class _ArchivoGridItem extends StatelessWidget {
  final File archivo;
  final VoidCallback onRemover;
  const _ArchivoGridItem(
      {required this.archivo, required this.onRemover});

  bool get esImagen {
    final ext = archivo.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  bool get esVideo {
    final ext = archivo.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'webm'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: esImagen
              ? Image.file(archivo,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover)
              : Container(
                  color: esVideo
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: Center(
                    child: Icon(
                      esVideo
                          ? Icons.play_circle_rounded
                          : Icons.audio_file_rounded,
                      color: esVideo
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF10B981),
                      size: 36,
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemover,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
        if (!esImagen)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(
                esVideo ? 'VIDEO' : 'AUDIO',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Widget auxiliar sección ───────────────────────────────────

class _Seccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  const _Seccion({required this.icono, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: AppTheme.accent, size: 18),
        ),
        const SizedBox(width: 10),
        Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}