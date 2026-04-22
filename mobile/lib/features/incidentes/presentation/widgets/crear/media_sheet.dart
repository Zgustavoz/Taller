import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/core/config/theme/app_theme.dart';

// ─── Media Sheet ──────────────────────────────────────────────
class MediaSheet extends StatelessWidget {
  final VoidCallback onTomarFoto;
  final VoidCallback onGaleria;
  final VoidCallback onPickAudio;
  final VoidCallback onGrabarAudio;
  final bool grabando;

  const MediaSheet({
    super.key,
    required this.onTomarFoto,
    required this.onGaleria,
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
              _OpcionMedia(
                  icono: Icons.camera_alt_rounded,
                  label: 'Cámara',
                  color: const Color(0xFF3B82F6),
                  onTap: onTomarFoto),
              _OpcionMedia(
                  icono: Icons.photo_library_rounded,
                  label: 'Galería',
                  color: const Color(0xFF8B5CF6),
                  onTap: onGaleria),
              _OpcionMedia(
                  icono: Icons.audio_file_rounded,
                  label: 'Audio',
                  color: const Color(0xFFF59E0B),
                  onTap: onPickAudio),
              _OpcionMedia(
                  icono: grabando ? Icons.stop_rounded : Icons.mic_rounded,
                  label: grabando ? 'Detener' : 'Grabar',
                  color: grabando ? AppTheme.error : const Color(0xFF6B7280),
                  onTap: onGrabarAudio),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OpcionMedia extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OpcionMedia(
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

// ─── Archivo Item (grid de archivos seleccionados) ────────────
class ArchivoItem extends StatelessWidget {
  final File archivo;
  final VoidCallback onRemover;
  const ArchivoItem(
      {super.key, required this.archivo, required this.onRemover});

  bool get esImagen => ['jpg', 'jpeg', 'png', 'webp', 'gif']
      .contains(archivo.path.split('.').last.toLowerCase());
  bool get esVideo => ['mp4', 'mov', 'avi', 'webm']
      .contains(archivo.path.split('.').last.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
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
        top: 4, right: 4,
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
          bottom: 4, left: 4,
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
    ]);
  }
}