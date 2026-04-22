import 'package:flutter/material.dart';
import 'package:mobile/core/config/theme/app_theme.dart';


class PantallaAnalizando extends StatefulWidget {
  final String mensaje;
  const PantallaAnalizando({super.key, required this.mensaje});

  @override
  State<PantallaAnalizando> createState() => _PantallaAnalizandoState();
}

class _PantallaAnalizandoState extends State<PantallaAnalizando>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _paso = 0;
  final _pasos = [
    '📤 Subiendo archivos...',
    '🤖 Analizando con Gemini IA...',
    '🔍 Clasificando el incidente...',
    '📍 Buscando talleres cercanos...',
    '🔔 Notificando talleres...',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _anim = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() => _paso = (_paso + 1) % _pasos.length);
      return true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Espera a que termine el análisis...'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Transform.rotate(
                    angle: _anim.value * 2 * 3.14159,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accent, width: 3),
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: Colors.white, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Procesando tu emergencia',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _pasos[_paso],
                    key: ValueKey(_paso),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                LinearProgressIndicator(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.accent),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gemini está analizando tus archivos\ny buscando talleres cercanos',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}