import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/custom_text_field.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              nombre: _nombreCtrl.text.trim(),
              apellido: _apellidoCtrl.text.trim(),
              usuario: _usuarioCtrl.text.trim(),
              correo: _correoCtrl.text.trim(),
              password: _passwordCtrl.text,
              telefono: _telefonoCtrl.text.isEmpty ? null : _telefonoCtrl.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Cuenta creada! Inicia sesión'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          context.go('/login');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensaje),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completa el formulario para registrarte',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Formulario ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nombre y Apellido en fila
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              hint: 'Nombre',
                              icon: Icons.badge_outlined,
                              controller: _nombreCtrl,
                              validator: (v) =>
                                  v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              hint: 'Apellido',
                              icon: Icons.badge_outlined,
                              controller: _apellidoCtrl,
                              validator: (v) =>
                                  v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        hint: 'Usuario',
                        icon: Icons.alternate_email_rounded,
                        controller: _usuarioCtrl,
                        validator: (v) {
                          if (v!.isEmpty) return 'Ingresa un usuario';
                          if (v.length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        hint: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        hint: 'Contraseña',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordCtrl,
                        isPassword: true,
                        validator: (v) {
                          if (v!.isEmpty) return 'Ingresa una contraseña';
                          if (v.length < 8) return 'Mínimo 8 caracteres';
                          if (!v.contains(RegExp(r'[A-Z]')))
                            return 'Debe tener una mayúscula';
                          if (!v.contains(RegExp(r'[0-9]')))
                            return 'Debe tener un número';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        hint: 'Teléfono (opcional)',
                        icon: Icons.phone_outlined,
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 28),

                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: state is AuthLoading ? null : _submit,
                            child: state is AuthLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Crear cuenta'),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}