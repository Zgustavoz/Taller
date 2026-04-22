import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:mobile/features/incidentes/presentation/widgets/detalle/multimedia_item.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../bloc/incidente_bloc.dart';
import '../bloc/incidente_event.dart';
import '../bloc/incidente_state.dart';
import '../../domain/entities/incidente_entity.dart';
import '../../data/models/taller_cercano_model.dart';
import '../widgets/detalle/cards_detalle.dart';
import '../widgets/shared/widgets_compartidos.dart';

class DetalleIncidenteScreen extends StatelessWidget {
  final int incidenteId;
  const DetalleIncidenteScreen({super.key, required this.incidenteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidenteBloc()..add(IncidenteCargarDetalle(incidenteId)),
      child: _DetalleView(incidenteId: incidenteId),
    );
  }
}

class _DetalleView extends StatefulWidget {
  final int incidenteId;
  const _DetalleView({required this.incidenteId});

  @override
  State<_DetalleView> createState() => _DetalleViewState();
}

class _DetalleViewState extends State<_DetalleView> {
  Timer? _pollingTimer;
  String? _ultimoEstado;

  @override
  void initState() {
    super.initState();
    // Polling cada 10 segundos para estados activos
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      // Solo hacer polling si el incidente no está resuelto/cancelado
      if (_ultimoEstado != 'resuelto' && _ultimoEstado != 'cancelado') {
        context.read<IncidenteBloc>().add(
            IncidenteCargarDetalle(widget.incidenteId));
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

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
              // Actualizar el último estado conocido
              _ultimoEstado = state.incidente.estado;
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<IncidenteBloc>()
                          .add(IncidenteCargarDetalle(widget.incidenteId)),
                      child: const Text('Reintentar'),
                    ),
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
        // ── AppBar ────────────────────────────────────────
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
                            incidente.estado.replaceAll('_', ' ').toUpperCase(),
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
                          Text('ETA: ${incidente.tiempoEstimadoLlegadaMin} min',
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
                Tarjeta(
                  child: Column(children: [
                    if (incidente.textoDireccion != null)
                      FilaDetalle(
                          icono: Icons.location_on_rounded,
                          label: 'Ubicación',
                          valor: incidente.textoDireccion!),
                    if (incidente.latitud != null)
                      FilaDetalle(
                          icono: Icons.gps_fixed_rounded,
                          label: 'Coordenadas',
                          valor:
                              '${incidente.latitud!.toStringAsFixed(5)}, ${incidente.longitud!.toStringAsFixed(5)}'),
                    FilaDetalle(
                        icono: Icons.access_time_rounded,
                        label: 'Reportado',
                        valor: _fmt(incidente.creadoAt)),
                    if (incidente.descripcion != null)
                      FilaDetalle(
                          icono: Icons.description_rounded,
                          label: 'Descripción',
                          valor: incidente.descripcion!),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Análisis IA ───────────────────────────
                if (incidente.analisisIa != null) ...[
                  TituloSeccion(
                      icono: Icons.psychology_rounded,
                      titulo: 'Análisis de IA',
                      color: const Color(0xFF3B82F6)),
                  const SizedBox(height: 8),
                  CardIA(analisis: incidente.analisisIa!),
                  const SizedBox(height: 14),
                ],

                // ── Ficha resumen ─────────────────────────
                if (incidente.fichaResumen != null ||
                    incidente.analisisIa?.fichaResumen != null) ...[
                  TituloSeccion(
                      icono: Icons.assignment_rounded,
                      titulo: 'Ficha del incidente',
                      color: const Color(0xFF8B5CF6)),
                  const SizedBox(height: 8),
                  CardFicha(
                      ficha: incidente.fichaResumen ??
                          incidente.analisisIa!.fichaResumen!),
                  const SizedBox(height: 14),
                ],

                // ── Talleres ──────────────────────────────
                TituloSeccion(
                    icono: Icons.build_rounded,
                    titulo: incidente.tallerAsignadoId != null
                        ? 'Taller asignado'
                        : 'Talleres candidatos (${talleresCercanos.length})',
                    color: const Color(0xFF10B981)),
                const SizedBox(height: 8),
                if (talleresCercanos.isEmpty)
                  Tarjeta(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          incidente.tallerAsignadoId != null
                              ? 'Taller asignado'
                              : 'Sin talleres cercanos disponibles',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  )
                else
                  ...talleresCercanos.map((t) => TallerCard(taller: t)),
                const SizedBox(height: 8),

                // Botón ver mapa
                ElevatedButton.icon(
                  onPressed: () => context
                      .push('/mapa?incidente_id=${incidente.id}'),
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

                // Botón pagar — solo si está resuelto
                if (incidente.estado == 'resuelto') ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => context.push(
                      '/pago/${incidente.id}?desc=${Uri.encodeComponent(incidente.descripcion ?? "")}',
                    ),
                    icon: const Icon(Icons.payment_rounded,
                        color: Colors.white),
                    label: const Text('Pagar servicio',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // ── Multimedia ────────────────────────────
                TituloSeccion(
                    icono: Icons.photo_library_rounded,
                    titulo: 'Evidencia (${incidente.multimedia.length})',
                    color: const Color(0xFFEC4899)),
                const SizedBox(height: 8),
                incidente.multimedia.isEmpty
                    ? Tarjeta(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 40, color: Colors.grey.shade300),
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
                        itemBuilder: (_, i) => MultimediaItem(
                          media: incidente.multimedia[i],
                          incidenteId: incidente.id,
                        ),
                      ),
                const SizedBox(height: 14),

                // ── Historial ─────────────────────────────
                if (incidente.historial.isNotEmpty) ...[
                  TituloSeccion(
                      icono: Icons.timeline_rounded,
                      titulo: 'Historial',
                      color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 8),
                  CardHistorial(historial: incidente.historial),
                  const SizedBox(height: 14),
                ],

                // ── Asignaciones ──────────────────────────
                if (incidente.asignaciones.isNotEmpty) ...[
                  TituloSeccion(
                      icono: Icons.assignment_ind_rounded,
                      titulo: 'Asignaciones',
                      color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  CardAsignaciones(asignaciones: incidente.asignaciones),
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