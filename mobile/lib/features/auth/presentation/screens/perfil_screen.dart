import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import '../../../../core/config/theme/app_theme.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/domain/entities/usuario_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _picker = img_picker.ImagePicker();
  File? _fotoPerfil;
  bool _isLoading = false;
  UsuarioEntity? _usuario;

  Future<void> _cargarUsuario() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _usuario = authState.usuario;
      });
    }
  }

  Future<void> _seleccionarFoto() async {
    final foto = await _picker.pickImage(
      source: img_picker.ImageSource.gallery,
      imageQuality: 80,
    );
    if (foto != null) {
      setState(() => _fotoPerfil = File(foto.path));
    }
  }

  Future<void> _subirFoto() async {
    if (_fotoPerfil == null || _usuario == null) return;
    setState(() => _isLoading = true);
    try {
      final repository = AuthRepository();
      final actualizacion = await repository.subirFotoPerfil(_usuario!.id, _fotoPerfil!);
      context.read<AuthBloc>().add(AuthUsuarioActualizado(actualizacion),);
      setState(() {
        _usuario = actualizacion;
        _fotoPerfil = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Foto de perfil actualizada'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final usuario = authState is AuthAuthenticated ? authState.usuario : _usuario;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.accent.withValues(alpha: 0.2),

                          backgroundImage: _fotoPerfil != null
                              ? FileImage(_fotoPerfil!)
                              : (usuario.url != null && usuario.url!.isNotEmpty
                                  ? NetworkImage(usuario.url!)
                                  : null),

                          child: (_fotoPerfil == null &&
                                  (usuario.url == null || usuario.url!.isEmpty))
                              ? Text(
                                  usuario.nombre.isNotEmpty
                                      ? usuario.nombre[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _seleccionarFoto,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_fotoPerfil != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        _fotoPerfil!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _subirFoto,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(_isLoading ? 'Subiendo...' : 'Guardar foto'),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text('Nombre', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('${usuario.nombre} ${usuario.apellido}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Usuario', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(usuario.usuario, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Correo', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(usuario.correo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (usuario.telefono != null && usuario.telefono!.isNotEmpty) ...[
                    Text('Teléfono', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Text(usuario.telefono!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
    );
  }
}
