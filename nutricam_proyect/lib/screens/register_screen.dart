import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 40,
              bottom: 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/logo.png", width: 125, height: 125),
                Text(
                  "¡Bienvenido!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.logoColor,
                  ),
                ),
                Text(
                  "Complete los campos",
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                ),

                SizedBox(height: 30),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    label: Text(
                      "Nombre",
                      style: TextStyle(color: AppColors.accent),
                    ),
                    hintText: "Introduzca su nombre",
                    hintStyle: TextStyle(color: AppColors.accent),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                TextField(
                  controller: surnameController,
                  decoration: InputDecoration(
                    label: Text(
                      "Apellido",
                      style: TextStyle(color: AppColors.accent),
                    ),
                    hintText: "Introduzca su apellido",
                    hintStyle: TextStyle(color: AppColors.accent),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    label: Text(
                      "Email",
                      style: TextStyle(color: AppColors.accent),
                    ),
                    hintText: "Introduzca su correo",
                    hintStyle: TextStyle(color: AppColors.accent),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                TextField(
                  decoration: InputDecoration(
                    label: Text(
                      "Fecha de nacimiento",
                      style: TextStyle(color: AppColors.accent),
                    ),
                    hintText: "Seleccione su fecha de nacimiento",
                    hintStyle: TextStyle(color: AppColors.accent),
                    prefixIcon: Icon(Icons.calendar_today),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  controller: birthDateController,
                  readOnly: true,
                  onTap: _selectDate,
                ),

                SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    label: Text(
                      "Contraseña",
                      style: TextStyle(color: AppColors.accent),
                    ),
                    hintText: "Introduzca su contraseña",
                    hintStyle: TextStyle(color: AppColors.accent),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text;
                    final surname = surnameController.text;
                    final birthDate = birthDateController.text;
                    final email = emailController.text;
                    final password = passwordController.text;

                    if (name.isEmpty || surname.isEmpty || birthDate.isEmpty || email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Complete todos los campos")),
                      );
                      return;
                    }

                    final userData = await registrarUsuario(
                      name,
                      surname,
                      birthDate,
                      email,
                      password,
                    );

                    if (userData != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Usuario registrado!")),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(
                            userName: userData['name'],   // ← NOMBRE REAL DEVUELTO POR BACKEND
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error al registrar")),
                      );
                    }

                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(250, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    "Registrarme",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                SizedBox(height: 15),

                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(250, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  child: Text(
                    "Tengo una cuenta",
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: "Seleccione su fecha de nacimiento",
    );

    if (picked != null) {
      setState(() {
        birthDateController.text = picked.toString().split(" ")[0];
      });
    }
  }

  Future<Map<String, dynamic>?> registrarUsuario(
      String name,
      String surname,
      String birthDate,
      String email,
      String password,
    ) async {

    final url = Uri.parse("http://10.0.2.2:8080/register");

    final body = jsonEncode({
      "name": name,
      "surname": surname,
      "birthDate": birthDate,
      "email": email,
      "password": password,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body);   // ← DEVUELVE EL USUARIO COMPLETO
    }

    return null;  // Error al registrar
  }

}
