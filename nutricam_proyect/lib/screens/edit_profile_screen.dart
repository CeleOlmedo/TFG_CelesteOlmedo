import 'package:flutter/material.dart';
import 'package:nutricam_proyect/components/user.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController surnameController;
  late TextEditingController birthDateController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    surnameController = TextEditingController(text: widget.user.surname);
    birthDateController = TextEditingController(text: widget.user.birthDate);
  }

  void _saveChanges() async {
    final updatedUser = User(
      id: widget.user.id,
      name: nameController.text,
      surname: surnameController.text,
      email: widget.user.email,
      birthDate: birthDateController.text,
    );

    bool ok = await UserService.updateUser(updatedUser);

    if (ok) {
      UserSession.currentUser = updatedUser;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar cambios")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text("Editar Perfil"), backgroundColor: AppColors.background),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: surnameController,
              decoration: InputDecoration(labelText: 'Apellido'),
            ),
            TextField(
              controller: birthDateController,
              decoration: InputDecoration(labelText: 'Fecha de nacimiento (YYYY-MM-DD)'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.logoColor),
              child: Text("Guardar cambios", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
