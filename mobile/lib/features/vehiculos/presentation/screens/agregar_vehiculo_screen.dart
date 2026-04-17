import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import '../../../../core/config/theme/app_theme.dart';
import '../../../../core/common/widgets/custom_text_field.dart';
import '../bloc/vehiculo_bloc.dart';
import '../bloc/vehiculo_event.dart';
import '../bloc/vehiculo_state.dart';

class AgregarVehiculoScreen extends StatefulWidget {
  const AgregarVehiculoScreen({super.key});

  @override
  State<AgregarVehiculoScreen> createState() => _AgregarVehiculoScreenState();
}

class _AgregarVehiculoScreenState extends State<AgregarVehiculoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _tipoSeleccionado = 'sedan';
  File? _fotoVehiculo;
  final img_picker.ImagePicker _picker = img_picker.ImagePicker();

  final List<Map<String, dynamic>> _tipos = [
    {'valor': 'sedan', 'label': 'Sedán', 'icono': Icons.directions_car_rounded},
    {'valor': 'suv', 'label': 'SUV', 'icono': Icons.directions_car_filled_rounded},
    {'valor': 'pickup', 'label': 'Pickup', 'icono': Icons.local_shipping_rounded},
    {'valor': 'moto', 'label': 'Moto', 'icono': Icons.two_wheeler_rounded},
    {'valor': 'van', 'label': 'Van', 'icono': Icons.airport_shuttle_rounded},
    {'valor': 'camion', 'label': 'Camión', 'icono': Icons.fire_truck_rounded},
  ];

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _yearCtrl.dispose();
    _placaCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      context.read<VehiculoBloc>().add(VehiculoCrear({
            'marca': _marcaCtrl.text.trim(),
            'modelo': _modeloCtrl.text.trim(),
            'year': int.parse(_yearCtrl.text.trim()),
            'placa': _placaCtrl.text.trim().toUpperCase(),
            'color': _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
            'tipo': _tipoSeleccionado,
          },
          fotoPath: _fotoVehiculo?.path,
      ));
    }
  }

  Future<void> _pickFoto() async {
    final foto = await _picker.pickImage(
      source: img_picker.ImageSource.gallery,
      imageQuality: 75,
    );
    if (foto != null) {
      setState(() => _fotoVehiculo = File(foto.path));
    }
  }

  void _removerFoto() {
    setState(() => _fotoVehiculo = null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehiculoBloc, VehiculoState>(
      listener: (context, state) {
        if (state is VehiculoCreadoExito) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Vehículo registrado'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (state is VehiculoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensaje),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          title: const Text('Registrar Vehículo',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Ícono del tipo seleccionado
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _tipos.firstWhere(
                            (t) => t['valor'] == _tipoSeleccionado)['icono']
                        as IconData,
                    size: 44,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _pickFoto,
                child: Column(
                  children: [
                    if (_fotoVehiculo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _fotoVehiculo!,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.accent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined,
                                size: 32, color: AppTheme.accent),
                            const SizedBox(height: 8),
                            Text('Agregar foto',
                                style: TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (_fotoVehiculo != null) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _removerFoto,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Eliminar foto'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de vehículo
              const Text('Tipo de vehículo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tipos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final t = _tipos[i];
                    final sel = _tipoSeleccionado == t['valor'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _tipoSeleccionado = t['valor']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        decoration: BoxDecoration(
                          color:
                              sel ? AppTheme.accent : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel
                                ? AppTheme.accent
                                : Colors.grey.shade200,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t['icono'] as IconData,
                                color: sel ? Colors.white : Colors.grey,
                                size: 24),
                            const SizedBox(height: 4),
                            Text(t['label'],
                                style: TextStyle(
                                    fontSize: 10,
                                    color: sel
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Campos
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      hint: 'Marca',
                      icon: Icons.branding_watermark_rounded,
                      controller: _marcaCtrl,
                      validator: (v) =>
                          v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      hint: 'Modelo',
                      icon: Icons.directions_car_rounded,
                      controller: _modeloCtrl,
                      validator: (v) =>
                          v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      hint: 'Año',
                      icon: Icons.calendar_today_rounded,
                      controller: _yearCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v!.isEmpty) return 'Requerido';
                        final y = int.tryParse(v);
                        if (y == null || y < 1900 || y > 2026) {
                          return 'Año inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      hint: 'Color',
                      icon: Icons.color_lens_rounded,
                      controller: _colorCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                hint: 'Placa (ej: ABC-123)',
                icon: Icons.badge_rounded,
                controller: _placaCtrl,
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa la placa' : null,
              ),
              const SizedBox(height: 32),

              BlocBuilder<VehiculoBloc, VehiculoState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed:
                        state is VehiculoLoading ? null : _guardar,
                    child: state is VehiculoLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Registrar Vehículo'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}