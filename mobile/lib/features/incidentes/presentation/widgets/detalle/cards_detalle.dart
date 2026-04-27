import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/config/theme/app_theme.dart';
import 'package:mobile/features/incidentes/data/models/taller_cercano_model.dart';
import 'package:mobile/features/incidentes/domain/entities/incidente_entity.dart';
import 'package:mobile/features/incidentes/presentation/bloc/incidente_bloc.dart';
import 'package:mobile/features/incidentes/presentation/bloc/incidente_event.dart';
import 'package:mobile/features/incidentes/presentation/bloc/incidente_state.dart';
import 'package:mobile/features/incidentes/presentation/widgets/shared/widgets_compartidos.dart';


// ─── Card IA ──────────────────────────────────────────────────
class CardIA extends StatelessWidget {
  final AnalisisIA analisis;
  const CardIA({super.key, required this.analisis});

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
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
            Badge(
                texto: analisis.tipoDetectado.replaceAll('_', ' '),
                color: const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Badge(
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
                    Icon(Icons.mic_rounded, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text('Transcripción de audio',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                  .map((d) =>
                      Badge(texto: d, color: const Color(0xFFEF4444)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Card Ficha ───────────────────────────────────────────────
class CardFicha extends StatelessWidget {
  final FichaResumen ficha;
  const CardFicha({super.key, required this.ficha});

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
    return Tarjeta(
      color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
      border: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Badge(
              texto: '🚨 ${ficha.urgencia.toUpperCase()}',
              color: _colorUrgencia(ficha.urgencia)),
          const SizedBox(height: 12),
          _FichaFila(label: 'Problema', valor: ficha.problemaPrincipal),
          _FichaFila(label: 'Recomendación', valor: ficha.recomendacion),
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
                  .map((h) =>
                      Badge(texto: h, color: const Color(0xFF8B5CF6)))
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

// ─── Card Historial ───────────────────────────────────────────
class CardHistorial extends StatelessWidget {
  final List<HistorialItem> historial;
  const CardHistorial({super.key, required this.historial});

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
    return Tarjeta(
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
                Column(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: Icon(_iconActor(h.tipoActor),
                        color: color, size: 16),
                  ),
                  if (!esUltimo)
                    Expanded(
                        child: Container(
                            width: 2, color: Colors.grey.shade200)),
                ]),
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
                        Text(h.tipoActor.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                color: color.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600)),
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

// ─── Card Asignaciones ────────────────────────────────────────
class CardAsignaciones extends StatelessWidget {
  final List<AsignacionItem> asignaciones;
  const CardAsignaciones({super.key, required this.asignaciones});

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
    return Tarjeta(
      child: Column(
        children: asignaciones.map((a) {
          final color = _colorEstado(a.estado);
          // Mostrar nombre del taller si está disponible, sino "Taller #id"
          final nombreTaller = a.nombreTaller ?? 'Taller #${a.tallerId}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.build_rounded,
                    color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombreTaller,
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
              Badge(texto: a.estado.toUpperCase(), color: color),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Taller Card ──────────────────────────────────────────────
class TallerCard extends StatelessWidget {
  final TallerCercanoModel taller;
  const TallerCard({super.key, required this.taller});

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
          width: 44, height: 44,
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
          width: 10, height: 10,
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

class CardCalificacion extends StatefulWidget {
  final int incidenteId;
  const CardCalificacion({super.key, required this.incidenteId});

  @override
  State<CardCalificacion> createState() => _CardCalificacionState();
}

class _CardCalificacionState extends State<CardCalificacion> {
  int _estrellasSeleccionadas = 0;
  final _comentarioCtrl = TextEditingController();
  bool _yaCalificado = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncidenteBloc, IncidenteState>(
      listener: (context, state) {
        if (state is IncidenteCalificadoExito) {
          setState(() => _yaCalificado = true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '⭐ Calificación enviada. Nuevo promedio del taller: ${state.nuevoPromedio.toStringAsFixed(1)}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        }
        if (state is IncidenteError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.mensaje),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: _yaCalificado
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text('¡Gracias por tu calificación!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981))),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Cómo fue el servicio?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),

                  // Estrellas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final estrella = i + 1;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _estrellasSeleccionadas = estrella),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            estrella <= _estrellasSeleccionadas
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: estrella <= _estrellasSeleccionadas
                                ? const Color(0xFFF59E0B)
                                : Colors.grey.shade300,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_estrellasSeleccionadas > 0) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _textoEstrella(_estrellasSeleccionadas),
                        style: TextStyle(
                            color: _colorEstrella(_estrellasSeleccionadas),
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _comentarioCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Comentario opcional...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<IncidenteBloc, IncidenteState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is IncidenteLoading
                              ? null
                              : () {
                                  context.read<IncidenteBloc>().add(
                                        IncidenteCalificar(
                                          widget.incidenteId,
                                          _estrellasSeleccionadas,
                                          comentario: _comentarioCtrl
                                                  .text.trim().isEmpty
                                              ? null
                                              : _comentarioCtrl.text.trim(),
                                        ),
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: state is IncidenteLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Enviar calificación',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  String _textoEstrella(int n) {
    switch (n) {
      case 1: return 'Muy malo 😞';
      case 2: return 'Malo 😕';
      case 3: return 'Regular 😐';
      case 4: return 'Bueno 😊';
      case 5: return 'Excelente 🌟';
      default: return '';
    }
  }

  Color _colorEstrella(int n) {
    if (n <= 2) return AppTheme.error;
    if (n == 3) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}