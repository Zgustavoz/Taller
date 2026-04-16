import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../bloc/incidente_bloc.dart';
import '../bloc/incidente_event.dart';
import '../bloc/incidente_state.dart';
import '../../domain/entities/incidente_entity.dart';
import '../../domain/entities/multimedia_entity.dart';

class DetalleIncidenteScreen extends StatelessWidget {
  final int incidenteId;
  const DetalleIncidenteScreen({super.key, required this.incidenteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidenteBloc()..add(IncidenteCargarDetalle(incidenteId)),
      child: const _DetalleView(),
    );
  }
}

class _DetalleView extends StatelessWidget {
  const _DetalleView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocBuilder<IncidenteBloc, IncidenteState>(
        builder: (context, state) {
          if (state is IncidenteLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (state is IncidenteDetalleCargado) {
            return _DetalleContenido(incidente: state.incidente);
          }
          if (state is IncidenteError) {
            return Center(child: Text(state.mensaje));
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _DetalleContenido extends StatelessWidget {
  final IncidenteEntity incidente;
  const _DetalleContenido({required this.incidente});

  Color _colorEstado(String e) {
    switch (e) {
      case 'pendiente': return const Color(0xFFF59E0B);
      case 'analizando': return const Color(0xFF3B82F6);
      case 'asignado': return const Color(0xFF8B5CF6);
      case 'en_progreso': return const Color(0xFFEC4899);
      case 'resuelto': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(incidente.estado);
    return CustomScrollView(
      slivers: [
        // ── AppBar con degradado ───────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Incidente #${incidente.id}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        incidente.estado.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded),
              onPressed: () => _agregarArchivos(context),
              tooltip: 'Agregar evidencia',
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Info general ─────────────────────────────
                _Tarjeta(
                  child: Column(
                    children: [
                      _InfoFila(
                        icono: Icons.location_on_rounded,
                        label: 'Ubicación',
                        valor: incidente.textoDireccion ?? 'Registrada por GPS',
                      ),
                      if (incidente.latitud != null)
                        _InfoFila(
                          icono: Icons.gps_fixed_rounded,
                          label: 'Coordenadas',
                          valor:
                              '${incidente.latitud!.toStringAsFixed(5)}, ${incidente.longitud!.toStringAsFixed(5)}',
                        ),
                      if (incidente.nivelPrioridad != null)
                        _InfoFila(
                          icono: Icons.priority_high_rounded,
                          label: 'Prioridad',
                          valor: '${incidente.nivelPrioridad}/5',
                          color: _colorPrioridad(incidente.nivelPrioridad!),
                        ),
                      _InfoFila(
                        icono: Icons.access_time_rounded,
                        label: 'Reportado',
                        valor: _formatFecha(incidente.creadoAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Descripción ──────────────────────────────
                if (incidente.descripcion != null) ...[
                  _Tarjeta(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.description_rounded,
                              color: AppTheme.accent, size: 18),
                          const SizedBox(width: 8),
                          const Text('Descripción',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                        ]),
                        const SizedBox(height: 10),
                        Text(incidente.descripcion!,
                            style: TextStyle(
                                color: Colors.grey.shade600, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Análisis IA ──────────────────────────────
                if (incidente.analisisIa != null) ...[
                  _Tarjeta(
                    color: const Color(0xFF3B82F6).withOpacity(0.05),
                    border: const Color(0xFF3B82F6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.psychology_rounded,
                              color: Color(0xFF3B82F6), size: 18),
                          const SizedBox(width: 8),
                          const Text('Análisis de IA',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6))),
                        ]),
                        const SizedBox(height: 10),
                        Text(incidente.analisisIa!,
                            style: TextStyle(
                                color: Colors.grey.shade700, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Multimedia ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Evidencia adjunta',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textPrimary)),
                    Text('${incidente.multimedia.length} archivos',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),

                if (incidente.multimedia.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('Sin archivos adjuntos',
                              style:
                                  TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _agregarArchivos(BuildContext context) async {
    final bloc = context.read<IncidenteBloc>();
    final picker = ImagePicker();
    final imgs = await picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      bloc.add(IncidenteSubirArchivos(
          incidente.id, imgs.map((x) => File(x.path)).toList()));
    }
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

  String _formatFecha(DateTime f) =>
      '${f.day}/${f.month}/${f.year} ${f.hour}:${f.minute.toString().padLeft(2, '0')}';
}

class _MultimediaItem extends StatelessWidget {
  final MultimediaEntity media;
  final int incidenteId;
  const _MultimediaItem({required this.media, required this.incidenteId});

  bool get esImagen => media.tipoArchivo == 'imagen';
  bool get esVideo => media.tipoArchivo == 'video';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _confirmarEliminar(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            esImagen
                ? Image.network(media.urlAlmacenamiento, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_rounded,
                              color: Colors.grey),
                        ))
                : Container(
                    color: esVideo
                        ? const Color(0xFF8B5CF6).withOpacity(0.15)
                        : const Color(0xFF10B981).withOpacity(0.15),
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
            // Badge tipo
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  media.tipoArchivo,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar archivo'),
        content: const Text('¿Seguro que deseas eliminar este archivo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<IncidenteBloc>().add(
                  IncidenteEliminarMultimedia(media.id, incidenteId));
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: border != null ? Border.all(color: border!) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _InfoFila extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final Color? color;
  const _InfoFila(
      {required this.icono,
      required this.label,
      required this.valor,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color ?? AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                Text(valor,
                    style: TextStyle(
                        fontSize: 14,
                        color: color ?? AppTheme.textPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}