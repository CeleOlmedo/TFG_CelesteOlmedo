import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/login_screen.dart';
import 'package:nutricam_proyect/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 18),
      firstDate: DateTime(1920),
      lastDate: today,
      helpText: 'Seleccioná tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final formattedDate =
        '${pickedDate.year.toString().padLeft(4, '0')}-'
        '${pickedDate.month.toString().padLeft(2, '0')}-'
        '${pickedDate.day.toString().padLeft(2, '0')}';

    setState(() {
      _birthDateController.text = formattedDate;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.register(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      switch (result.status) {
        case RegisterStatus.success:
          final user = result.user;

          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudo recuperar la información del usuario.',
                ),
              ),
            );
            return;
          }

          UserSession.currentUser = user;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Usuario registrado correctamente.',
              ),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                userName: user.name,
              ),
            ),
            (route) => false,
          );

          return;

        case RegisterStatus.emailAlreadyExists:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ya existe una cuenta registrada con ese correo.',
              ),
            ),
          );
          return;

        case RegisterStatus.invalidRequest:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Revisá los datos ingresados. '
                'La contraseña debe tener al menos 6 caracteres, '
                'letras y números.',
              ),
            ),
          );
          return;

        case RegisterStatus.serverError:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ocurrió un error en el servidor. '
                'Intentá nuevamente.',
              ),
            ),
          );
          return;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo conectar con el servidor. '
            'Intentá nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateRequiredField(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá $fieldName';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresá tu correo electrónico';
    }

    final emailExpression = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailExpression.hasMatch(email)) {
      return 'Ingresá un correo válido';
    }

    return null;
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Seleccioná tu fecha de nacimiento';
    }

    final date = DateTime.tryParse(value.trim());

    if (date == null) {
      return 'La fecha no es válida';
    }

    if (date.isAfter(DateTime.now())) {
      return 'La fecha no puede ser futura';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresá una contraseña';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return 'La contraseña debe incluir letras y números';
    }

    return null;
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 125,
                  height: 125,
                ),
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.logoColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completá tus datos para crear una cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    label: 'Nombre',
                    hint: 'Ingresá tu nombre',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    return _validateRequiredField(
                      value,
                      'tu nombre',
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _surnameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    label: 'Apellido',
                    hint: 'Ingresá tu apellido',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (value) {
                    return _validateRequiredField(
                      value,
                      'tu apellido',
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: _buildInputDecoration(
                    label: 'Email',
                    hint: 'tu@email.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: _buildInputDecoration(
                    label: 'Fecha de nacimiento',
                    hint: 'AAAA-MM-DD',
                    icon: Icons.calendar_today_outlined,
                  ),
                  validator: _validateBirthDate,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _register();
                    }
                  },
                  decoration: _buildInputDecoration(
                    label: 'Contraseña',
                    hint: 'Mínimo 6 caracteres, letras y números',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Registrarme',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _openLogin,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tengo una cuenta',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}