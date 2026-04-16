import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../domain/entities/vehiculo_entity.dart';
import '../bloc/vehiculo_bloc.dart';
import '../bloc/vehiculo_event.dart';
import '../bloc/vehiculo_state.dart';
import 'agregar_vehiculo_screen.dart';

class VehiculosScreen extends StatelessWidget {
  const VehiculosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VehiculoBloc()..add(VehiculoCargar()),
      child: const _VehiculosView(),
    );
  }
}

class _VehiculosView extends StatelessWidget {
  const _VehiculosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Mis Vehículos',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<VehiculoBloc>(),
              child: const AgregarVehiculoScreen(),
            ),
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Agregar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: BlocBuilder<VehiculoBloc, VehiculoState>(
        builder: (context, state) {
          if (state is VehiculoLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (state is VehiculoCargado) {
            if (state.vehiculos.isEmpty) {
              return _EmptyVehiculos(
                onAgregar: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<VehiculoBloc>(),
                      child: const AgregarVehiculoScreen(),
                    ),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () async =>
                  context.read<VehiculoBloc>().add(VehiculoCargar()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.vehiculos.length,
                itemBuilder: (_, i) => _VehiculoCard(
                  vehiculo: state.vehiculos[i],
                  onEliminar: () => _confirmarEliminar(
                      context, state.vehiculos[i].id),
                ),
              ),
            );
          }
          if (state is VehiculoError) {
            return Center(child: Text(state.mensaje));
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar vehículo'),
        content: const Text('¿Seguro que deseas eliminar este vehículo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<VehiculoBloc>().add(VehiculoEliminar(id));
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

class _VehiculoCard extends StatelessWidget {
  final VehiculoEntity vehiculo;
  final VoidCallback onEliminar;
  const _VehiculoCard({required this.vehiculo, required this.onEliminar});

  IconData _iconTipo(String? tipo) {
    switch (tipo) {
      case 'suv': return Icons.directions_car_filled_rounded;
      case 'pickup': return Icons.local_shipping_rounded;
      case 'moto': return Icons.two_wheeler_rounded;
      case 'van': return Icons.airport_shuttle_rounded;
      case 'camion': return Icons.fire_truck_rounded;
      default: return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_iconTipo(vehiculo.tipo),
                  color: AppTheme.accent, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehiculo.nombreCompleto,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(
                          texto: vehiculo.placa,
                          color: AppTheme.primary),
                      const SizedBox(width: 6),
                      if (vehiculo.color != null)
                        _Badge(
                            texto: vehiculo.color!,
                            color: Colors.grey.shade500),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEliminar,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 22),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _EmptyVehiculos extends StatelessWidget {
  final VoidCallback onAgregar;
  const _EmptyVehiculos({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_rounded,
                size: 56, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          const Text('Sin vehículos registrados',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Registra tu vehículo para reportar emergencias',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAgregar,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Agregar vehículo'),
          ),
        ],
      ),
    );
  }
}