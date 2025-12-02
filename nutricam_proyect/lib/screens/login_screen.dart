import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/components/user.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/register_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/logo.png",
                        width: 125,
                        height: 125,
                      ),
                      Text(
                        "NutriCam",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.logoColor,
                        ),
                      ),
                      Text(
                        "Creando hábitos saludables",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 60),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          label: Text(
                            "Email",
                            style: TextStyle(color: AppColors.accent),
                          ),
                          hintText: "tu@email.com",
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
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          label: Text(
                            "Contraseña",
                            style: TextStyle(color: AppColors.accent),
                          ),
                          hintText: "******",
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

                      SizedBox(height: 50),

                      ElevatedButton(
                        onPressed: () async {
                          final email = emailController.text;
                          final password = passwordController.text;
                          final userData = await loginUsuario(email, password);

                          if (userData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(
                                  userName: userData.name,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Email o contraseña incorrectos")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(250, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primary,
                          shadowColor: AppColors.primary,
                        ),
                        child: Text(
                          "Ingresar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 15),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
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
                          "Registrarse",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<User?> loginUsuario(String email, String password) async {
    final url = Uri.parse("http://10.0.2.2:8080/login");

    final body = jsonEncode({"email": email, "password": password});

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200 &&
        response.body.isNotEmpty &&
        response.body != "null") {
        
      final data = jsonDecode(response.body);

      // Convertir respuesta en un User
      final user = User.fromJson(data);

      // Guardar usuario globalmente
      UserSession.currentUser = user;

      return user;
    }

    return null;
  }



}
