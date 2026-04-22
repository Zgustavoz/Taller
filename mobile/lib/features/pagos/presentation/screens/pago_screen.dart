import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../bloc/pago_bloc.dart';
import '../bloc/pago_event.dart';
import '../bloc/pago_state.dart';

class PagoScreen extends StatefulWidget {
  final int incidenteId;
  final String descripcionIncidente;

  const PagoScreen({
    super.key,
    required this.incidenteId,
    required this.descripcionIncidente,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _montoCtrl = TextEditingController();

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirPaymentSheet(BuildContext context, PagoIntentCreado state) async {
    final bloc = context.read<PagoBloc>();
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: state.clientSecret,
          merchantDisplayName: 'Emergencias Vehiculares',
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6C63FF),
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
            bloc.add(PagoConfirmar(
              incidenteId: widget.incidenteId,
              paymentIntentId: state.paymentIntentId,
              monto: state.monto,
            ));
      }
    } on StripeException catch (e) {
      if (!mounted) return;
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago cancelado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.error.localizedMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // ← Volver al estado listo para reintentar
      bloc.add(PagoVerificar(widget.incidenteId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
      );
      bloc.add(PagoVerificar(widget.incidenteId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PagoBloc()..add(PagoVerificar(widget.incidenteId)),
      child: BlocConsumer<PagoBloc, PagoState>(
        listener: (context, state) {
          // Cuando el intent está listo, abrir el Payment Sheet
          if (state is PagoIntentCreado) {
            _abrirPaymentSheet(context, state);
          }
          if (state is PagoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensaje),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              title: const Text('Pagar servicio',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: switch (state) {
              PagoCargando() || PagoIntentCreado() => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accent),
                      SizedBox(height: 16),
                      Text('Procesando pago...'),
                    ],
                  ),
                ),
              PagoYaCompletado(infoPago: final info) => _PagoCompletado(info: info),
              PagoExitoso(monto: final m, comision: final c, montoTaller: final t) =>
                _PagoExitosoView(monto: m, comision: c, montoTaller: t),
              _ => _FormularioPago(
                  incidenteId: widget.incidenteId,
                  descripcion: widget.descripcionIncidente,
                  montoCtrl: _montoCtrl,
                  onPagar: () {
                    final monto = double.tryParse(_montoCtrl.text.trim());
                    if (monto == null || monto <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa un monto válido')),
                      );
                      return;
                    }
                    context.read<PagoBloc>().add(PagoIniciar(
                          incidenteId: widget.incidenteId,
                          monto: monto,
                        ));
                  },
                ),
            },
          );
        },
      ),
    );
  }
}

// ─── Formulario ───────────────────────────────────────────────
class _FormularioPago extends StatelessWidget {
  final int incidenteId;
  final String descripcion;
  final TextEditingController montoCtrl;
  final VoidCallback onPagar;

  const _FormularioPago({
    required this.incidenteId,
    required this.descripcion,
    required this.montoCtrl,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info incidente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.car_repair_rounded, color: AppTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Incidente #$incidenteId',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text(descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Desglose comisión
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
            ),
            child: const Column(children: [
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF6C63FF)),
                SizedBox(width: 6),
                Text('Distribución del pago',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                        fontSize: 13)),
              ]),
              SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Taller mecánico', style: TextStyle(fontSize: 13)),
                Text('90%', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Plataforma', style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text('10%', style: TextStyle(color: Colors.grey)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // Monto
          const Text('Monto del servicio',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          TextField(
            controller: montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accent),
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 24),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.accent, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const Spacer(),

          // Botón
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onPagar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.payment_rounded, color: Colors.white),
              label: const Text('Pagar con tarjeta',
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_rounded, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 5),
              Text('Pago seguro con Stripe',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Pago exitoso ─────────────────────────────────────────────
class _PagoExitosoView extends StatelessWidget {
  final double monto, comision, montoTaller;
  const _PagoExitosoView(
      {required this.monto, required this.comision, required this.montoTaller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 64),
          ),
          const SizedBox(height: 20),
          const Text('¡Pago exitoso!',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _Fila('Total pagado', '\$${monto.toStringAsFixed(2)}', bold: true),
              _Fila('Taller', '\$${montoTaller.toStringAsFixed(2)}'),
              _Fila('Comisión', '\$${comision.toStringAsFixed(2)}', grey: true),
            ]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Volver',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}

// ─── Pago ya completado ───────────────────────────────────────
class _PagoCompletado extends StatelessWidget {
  final Map<String, dynamic> info;
  const _PagoCompletado({required this.info});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 64),
          const SizedBox(height: 16),
          const Text('Servicio ya pagado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Este incidente fue pagado correctamente',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _Fila('Total', '\$${info['monto_total']}', bold: true),
              _Fila('Taller', '\$${info['monto_taller']}'),
              _Fila('Comisión', '\$${info['monto_comision']}', grey: true),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label, valor;
  final bool bold, grey;
  const _Fila(this.label, this.valor, {this.bold = false, this.grey = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, color: grey ? Colors.grey : Colors.grey.shade600)),
        Text(valor,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: grey ? Colors.grey : AppTheme.textPrimary)),
      ]),
    );
  }
}