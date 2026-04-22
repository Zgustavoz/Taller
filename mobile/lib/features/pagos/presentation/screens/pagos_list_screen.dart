import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/pagos/presentation/bloc/pago_bloc.dart';
import 'package:mobile/features/pagos/presentation/bloc/pago_event.dart';
import 'package:mobile/features/pagos/presentation/bloc/pago_state.dart';
// import '../../../../core/config/theme/app_theme.dart';
class PagosListScreen extends StatelessWidget {
  const PagosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PagoBloc()..add(PagoCargarLista()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Pagos'),
        ),
        body: BlocBuilder<PagoBloc, PagoState>(
          builder: (context, state) {

            if (state is PagoCargando) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is PagoListaCargada) {

              if (state.pagos.isEmpty) {
                return const Center(
                  child: Text('No tienes pagos registrados'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.pagos.length,
                itemBuilder: (_, i) {
                  final pago = state.pagos[i];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.payments_rounded),

                      title: Text(
                        'Incidente #${pago['id_incidente']}',
                      ),

                      subtitle: Text(
                        'Estado: ${pago['estado_pago']}',
                      ),

                      trailing: Text(
                        'Bs ${pago['monto_total']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            if (state is PagoError) {
              return Center(
                child: Text(state.mensaje),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}