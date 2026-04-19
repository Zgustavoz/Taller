import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../bloc/incidente_bloc.dart';
import '../bloc/incidente_event.dart';
import '../bloc/incidente_state.dart';
import '../../domain/entities/incidente_entity.dart';
import '../../domain/entities/multimedia_entity.dart';
import '../../data/models/taller_cercano_model.dart';

class DetalleIncidenteScreen extends StatelessWidget {
  final int incidenteId;
  const DetalleIncidenteScreen({super.key, required this.incidenteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          IncidenteBloc()..add(IncidenteCargarDetalle(incidenteId)),
      child: const _DetalleView(),
    );
  }
}

class _DetalleView extends StatelessWidget {
  const _DetalleView();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: BlocBuilder<IncidenteBloc, IncidenteState>(
          builder: (context, state) {
            if (state is IncidenteLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent));
            }
            if (state is IncidenteDetalleCargado) {
              return _DetalleContenido(
                incidente: state.incidente,
                talleresCercanos: state.talleresCercanos,
              );
            }
            if (state is IncidenteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 56, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(state.mensaje,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _DetalleContenido extends StatelessWidget {
  final IncidenteEntity incidente;
  final List<TallerCercanoModel> talleresCercanos;
  const _DetalleContenido(
      {required this.incidente, required this.talleresCercanos});

  Color _colorEstado(String e) {
    switch (e) {
      case 'pendiente': return const Color(0xFFF59E0B);
      case 'analizando': return const Color(0xFF3B82F6);
      case 'notificando': return const Color(0xFF8B5CF6);
      case 'asignado': return const Color(0xFFEC4899);
      case 'en_proceso': return const Color(0xFFEF4444);
      case 'resuelto': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(incidente.estado);

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar ──────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded),
              onPressed: () => _agregarArchivos(context),
              tooltip: 'Agregar evidencia',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            incidente.estado
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (incidente.nivelPrioridad != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '⚡ Prioridad ${incidente.nivelPrioridad}/5',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      Text('Incidente #${incidente.id}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      if (incidente.tiempoEstimadoLlegadaMin != null)
                        Row(children: [
                          const Icon(Icons.access_time_rounded,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                              'ETA: ${incidente.tiempoEstimadoLlegadaMin} min',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Info básica ───────────────────────────
                _Tarjeta(
                  child: Column(
                    children: [
                      if (incidente.textoDireccion != null)
                        _Fila(
                            icono: Icons.location_on_rounded,
                            label: 'Ubicación',
                            valor: incidente.textoDireccion!),
                      if (incidente.latitud != null)
                        _Fila(
                            icono: Icons.gps_fixed_rounded,
                            label: 'Coordenadas',
                            valor:
                                '${incidente.latitud!.toStringAsFixed(5)}, ${incidente.longitud!.toStringAsFixed(5)}'),
                      _Fila(
                          icono: Icons.access_time_rounded,
                          label: 'Reportado',
                          valor: _fmt(incidente.creadoAt)),
                      if (incidente.descripcion != null)
                        _Fila(
                            icono: Icons.description_rounded,
                            label: 'Descripción',
                            valor: incidente.descripcion!),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Análisis de IA ────────────────────────
                if (incidente.analisisIa != null) ...[
                  _TituloSeccion(
                      icono: Icons.psychology_rounded,
                      titulo: 'Análisis de IA',
                      color: const Color(0xFF3B82F6)),
                  const SizedBox(height: 8),
                  _CardIA(analisis: incidente.analisisIa!),
                  const SizedBox(height: 14),
                ],

                // ── Ficha resumen ─────────────────────────
                if (incidente.fichaResumen != null ||
                    incidente.analisisIa?.fichaResumen != null) ...[
                  _TituloSeccion(
                      icono: Icons.assignment_rounded,
                      titulo: 'Ficha del incidente',
                      color: const Color(0xFF8B5CF6)),
                  const SizedBox(height: 8),
                  _CardFicha(
                      ficha: incidente.fichaResumen ??
                          incidente.analisisIa!.fichaResumen!),
                  const SizedBox(height: 14),
                ],

                // ── Talleres cercanos / asignado ──────────
                _TituloSeccion(
                    icono: Icons.build_rounded,
                    titulo: incidente.tallerAsignadoId != null
                        ? 'Taller asignado'
                        : 'Talleres candidatos (${talleresCercanos.length})',
                    color: const Color(0xFF10B981)),
                const SizedBox(height: 8),
                if (talleresCercanos.isEmpty)
                  _Tarjeta(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          incidente.tallerAsignadoId != null
                              ? 'Taller #${incidente.tallerAsignadoId} asignado'
                              : 'Sin talleres cercanos disponibles',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  )
                else
                  ...talleresCercanos
                      .map((t) => _TallerCard(taller: t))
                      .toList(),


                const SizedBox(height: 8),
                // Botón ver en mapa
                ElevatedButton.icon(
                  onPressed: () => context.push('/mapa?incidente_id=${incidente.id}'),
                  icon: const Icon(Icons.map_rounded, color: Colors.white),
                  label: const Text('Ver talleres en mapa',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),                      
                const SizedBox(height: 14),

                // ── Multimedia ────────────────────────────
                _TituloSeccion(
                    icono: Icons.photo_library_rounded,
                    titulo:
                        'Evidencia (${incidente.multimedia.length})',
                    color: const Color(0xFFEC4899)),
                const SizedBox(height: 8),
                incidente.multimedia.isEmpty
                    ? _Tarjeta(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 40,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text('Sin archivos adjuntos',
                                  style: TextStyle(
                                      color: Colors.grey.shade400)),
                            ]),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: incidente.multimedia.length,
                        itemBuilder: (_, i) => _MultimediaItem(
                          media: incidente.multimedia[i],
                          incidenteId: incidente.id,
                        ),
                      ),
                const SizedBox(height: 14),

                // ── Historial ─────────────────────────────
                if (incidente.historial.isNotEmpty) ...[
                  _TituloSeccion(
                      icono: Icons.timeline_rounded,
                      titulo: 'Historial',
                      color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 8),
                  _CardHistorial(historial: incidente.historial),
                  const SizedBox(height: 14),
                ],

                // ── Asignaciones ──────────────────────────
                if (incidente.asignaciones.isNotEmpty) ...[
                  _TituloSeccion(
                      icono: Icons.assignment_ind_rounded,
                      titulo: 'Asignaciones',
                      color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  _CardAsignaciones(
                      asignaciones: incidente.asignaciones),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _agregarArchivos(BuildContext context) async {
    final bloc = context.read<IncidenteBloc>();
    final picker = img_picker.ImagePicker();
    final imgs = await picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      bloc.add(IncidenteSubirArchivos(
          incidente.id, imgs.map((x) => File(x.path)).toList()));
    }
  }

  String _fmt(DateTime f) =>
      '${f.day}/${f.month}/${f.year} ${f.hour}:${f.minute.toString().padLeft(2, '0')}';
}

// ─── Card IA ───────────────────────────────────────────────────

class _CardIA extends StatelessWidget {
  final AnalisisIA analisis;
  const _CardIA({required this.analisis});

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
      border: const Color(0xFF3B82F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.psychology_rounded,
                color: Color(0xFF3B82F6), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(analisis.resumen,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _Badge(
                texto: analisis.tipoDetectado.replaceAll('_', ' '),
                color: const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _Badge(
                texto:
                    '${(analisis.confianza * 100).toStringAsFixed(0)}% confianza',
                color: analisis.confianza > 0.7
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B)),
          ]),
          if (analisis.transcripcionAudio != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.mic_rounded,
                        size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text('Transcripción de audio',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 4),
                  Text(analisis.transcripcionAudio!,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ],
          if (analisis.danosDetectados.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Daños detectados:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analisis.danosDetectados
                  .map((d) => _Badge(
                      texto: d, color: const Color(0xFFEF4444)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Card Ficha ────────────────────────────────────────────────

class _CardFicha extends StatelessWidget {
  final FichaResumen ficha;
  const _CardFicha({required this.ficha});

  Color _colorUrgencia(String u) {
    switch (u) {
      case 'critica': return const Color(0xFFEF4444);
      case 'alta': return const Color(0xFFEC4899);
      case 'media': return const Color(0xFFF59E0B);
      default: return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
      border: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Badge(
                texto: '🚨 ${ficha.urgencia.toUpperCase()}',
                color: _colorUrgencia(ficha.urgencia)),
          ]),
          const SizedBox(height: 12),
          _FichaFila(label: 'Problema', valor: ficha.problemaPrincipal),
          _FichaFila(
              label: 'Recomendación', valor: ficha.recomendacion),
          _FichaFila(
              label: 'Especialidad', valor: ficha.especialidadRequerida),
          if (ficha.herramientasNecesarias.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Herramientas necesarias:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ficha.herramientasNecesarias
                  .map((h) => _Badge(
                      texto: h, color: const Color(0xFF8B5CF6)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FichaFila extends StatelessWidget {
  final String label;
  final String valor;
  const _FichaFila({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          Text(valor,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Card Historial ────────────────────────────────────────────

class _CardHistorial extends StatelessWidget {
  final List<HistorialItem> historial;
  const _CardHistorial({required this.historial});

  Color _colorActor(String actor) {
    switch (actor) {
      case 'ia': return const Color(0xFF3B82F6);
      case 'taller': return const Color(0xFF8B5CF6);
      case 'sistema': return const Color(0xFF10B981);
      default: return const Color(0xFFF59E0B);
    }
  }

  IconData _iconActor(String actor) {
    switch (actor) {
      case 'ia': return Icons.psychology_rounded;
      case 'taller': return Icons.build_rounded;
      case 'sistema': return Icons.settings_rounded;
      default: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        children: historial.asMap().entries.map((e) {
          final i = e.key;
          final h = e.value;
          final color = _colorActor(h.tipoActor);
          final esUltimo = i == historial.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: Icon(_iconActor(h.tipoActor),
                          color: color, size: 16),
                    ),
                    if (!esUltimo)
                      Expanded(
                        child: Container(
                            width: 2,
                            color: Colors.grey.shade200),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: esUltimo ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            h.estadoNuevo.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '${h.creadoAt.hour}:${h.creadoAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                        ]),
                        if (h.notas != null)
                          Text(h.notas!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          h.tipoActor.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              color: color.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Card Asignaciones ─────────────────────────────────────────

class _CardAsignaciones extends StatelessWidget {
  final List<AsignacionItem> asignaciones;
  const _CardAsignaciones({required this.asignaciones});

  Color _colorEstado(String e) {
    switch (e) {
      case 'aceptado': return const Color(0xFF10B981);
      case 'rechazado': return const Color(0xFFEF4444);
      case 'descartado': return Colors.grey;
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        children: asignaciones.map((a) {
          final color = _colorEstado(a.estado);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text('T${a.tallerId}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Taller #${a.tallerId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.textPrimary)),
                    if (a.distanciaKm != null)
                      Text('${a.distanciaKm!.toStringAsFixed(1)} km',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _Badge(
                  texto: a.estado.toUpperCase(), color: color),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Taller Card ───────────────────────────────────────────────

class _TallerCard extends StatelessWidget {
  final TallerCercanoModel taller;
  const _TallerCard({required this.taller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.build_rounded,
              color: Color(0xFF10B981), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(taller.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              Row(children: [
                const Icon(Icons.star_rounded,
                    size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 3),
                Text(taller.calificacion.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 10),
                if (taller.especialidades.isNotEmpty)
                  Expanded(
                    child: Text(
                      taller.especialidades.join(', '),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ]),
            ],
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: taller.estaDisponible
                ? const Color(0xFF10B981)
                : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ]),
    );
  }
}

// ─── Multimedia Item ───────────────────────────────────────────

class _MultimediaItem extends StatefulWidget {
  final MultimediaEntity media;
  final int incidenteId;
  const _MultimediaItem({required this.media, required this.incidenteId});

  @override
  State<_MultimediaItem> createState() => _MultimediaItemState();
}

class _MultimediaItemState extends State<_MultimediaItem> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (widget.media.tipoArchivo != 'audio') return;
    try {
      setState(() => _isLoadingAudio = true);
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.media.urlAlmacenamiento));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reproducir el audio')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.media.tipoArchivo == 'audio' ? _toggleAudio : null,
      onLongPress: () => _confirmarEliminar(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          widget.media.tipoArchivo == 'imagen'
              ? Image.network(widget.media.urlAlmacenamiento,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_rounded,
                            color: Colors.grey),
                      ))
              : Container(
                  color: widget.media.tipoArchivo == 'video'
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: Center(
                    child: _isLoadingAudio
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Icon(
                            widget.media.tipoArchivo == 'video'
                                ? Icons.play_circle_rounded
                                : _isPlaying
                                    ? Icons.pause_circle_rounded
                                    : Icons.play_circle_rounded,
                            color: widget.media.tipoArchivo == 'video'
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF10B981),
                            size: 36,
                          ),
                  ),
                ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(widget.media.tipoArchivo,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar archivo'),
        content: const Text('¿Eliminar este archivo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<IncidenteBloc>().add(
                  IncidenteEliminarMultimedia(widget.media.id, widget.incidenteId));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets compartidos ───────────────────────────────────────

class _Tarjeta extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? border;
  const _Tarjeta({required this.child, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: border != null ? Border.all(color: border!) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  const _Fila(
      {required this.icono, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, size: 16, color: AppTheme.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  const _Badge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  const _TituloSeccion(
      {required this.icono, required this.titulo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Text(titulo,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary)),
    ]);
  }
}