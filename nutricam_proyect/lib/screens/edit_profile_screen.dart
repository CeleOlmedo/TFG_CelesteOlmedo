import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/models/user.dart';
import 'package:nutricam_proyect/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _birthDateController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.user.name,
    );

    _surnameController = TextEditingController(
      text: widget.user.surname,
    );

    _birthDateController = TextEditingController(
      text: widget.user.birthDate,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedUser = User(
      id: widget.user.id,
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      email: widget.user.email,
      birthDate: _birthDateController.text.trim(),
      objective: widget.user.objective,
    );

    final success = await UserService.updateUser(updatedUser);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      UserSession.currentUser = updatedUser;
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error al guardar los cambios."),
      ),
    );
  }

  String? _validateRequiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "Ingresá $fieldName";
    }

    return null;
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Ingresá la fecha de nacimiento";
    }

    final date = DateTime.tryParse(value.trim());

    if (date == null) {
      return "Usá el formato AAAA-MM-DD";
    }

    if (date.isAfter(DateTime.now())) {
      return "La fecha no puede ser futura";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Editar perfil"),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  return _validateRequiredField(value, "el nombre");
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _surnameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Apellido",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  return _validateRequiredField(value, "el apellido");
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _birthDateController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: "Fecha de nacimiento",
                  hintText: "AAAA-MM-DD",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: _validateBirthDate,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.logoColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Guardar cambios",
                          style: TextStyle(color: Colors.white),
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