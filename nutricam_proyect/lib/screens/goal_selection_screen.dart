import 'package:flutter/material.dart';
import 'package:nutricam_proyect/components/user.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/services/user_service.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() =>
      _GoalSelectionScreenState();
}

class _GoalSelectionScreenState
    extends State<GoalSelectionScreen> {

  String? selectedGoal;

  @override
  void initState() {
    super.initState();
    selectedGoal = UserSession.currentUser?.objective;
  }

  Future<void> saveGoal() async {

    User user = UserSession.currentUser!;

    user.objective = selectedGoal;

    bool success = await UserService.updateUser(user);

    if(success){

      UserSession.currentUser = user;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Objetivo guardado correctamente"),
        ),
      );

      Navigator.pop(context);

    }else{

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al guardar objetivo"),
        ),
      );

    }
  }

  Widget goalTile(String title, String value){

    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: selectedGoal,
      activeColor: AppColors.primary,
      onChanged: (value){
        setState(() {
          selectedGoal = value;
        });
      },
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Objetivo Nutricional"),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            goalTile(
              "Bajar de peso",
              "BAJAR_PESO",
            ),

            goalTile(
              "Mantener peso",
              "MANTENER_PESO",
            ),

            goalTile(
              "Ganar masa muscular",
              "GANAR_MASA",
            ),

            goalTile(
              "Mejorar hábitos alimentarios",
              "HABITOS_SALUDABLES",
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: selectedGoal == null
                    ? null
                    : saveGoal,
                child: const Text(
                  "Guardar objetivo",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}