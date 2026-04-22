import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile/core/config/theme/app_theme.dart';
import 'package:mobile/features/incidentes/domain/entities/multimedia_entity.dart';
import 'package:mobile/features/incidentes/presentation/bloc/incidente_bloc.dart';
import 'package:mobile/features/incidentes/presentation/bloc/incidente_event.dart';


class MultimediaItem extends StatefulWidget {
  final MultimediaEntity media;
  final int incidenteId;
  const MultimediaItem(
      {super.key, required this.media, required this.incidenteId});

  @override
  State<MultimediaItem> createState() => _MultimediaItemState();
}

class _MultimediaItemState extends State<MultimediaItem> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
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
              ? Image.network(
                  widget.media.urlAlmacenamiento,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_rounded,
                        color: Colors.grey),
                  ),
                )
              : Container(
                  color: widget.media.tipoArchivo == 'video'
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: Center(
                    child: _isLoadingAudio
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
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
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar archivo'),
        content: const Text('¿Eliminar este archivo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<IncidenteBloc>().add(IncidenteEliminarMultimedia(
                  widget.media.id, widget.incidenteId));
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}