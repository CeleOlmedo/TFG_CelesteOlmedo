import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/models/user.dart';
import 'package:nutricam_proyect/services/user_service.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() =>
      _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? _selectedGoal;
  bool _isSaving = false;

  final List<GoalOption> _goals = const [
    GoalOption(
      title: "Bajar de peso",
      description: "Adoptar hábitos que favorezcan una reducción progresiva.",
      value: "BAJAR_PESO",
      icon: Icons.trending_down,
    ),
    GoalOption(
      title: "Mantener el peso",
      description: "Sostener una alimentación equilibrada y estable.",
      value: "MANTENER_PESO",
      icon: Icons.balance,
    ),
    GoalOption(
      title: "Ganar masa muscular",
      description: "Acompañar el aumento de masa muscular con la alimentación.",
      value: "GANAR_MASA",
      icon: Icons.fitness_center,
    ),
    GoalOption(
      title: "Mejorar hábitos alimentarios",
      description: "Incorporar progresivamente elecciones más saludables.",
      value: "HABITOS_SALUDABLES",
      icon: Icons.eco_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoal = UserSession.currentUser?.objective;
  }

  Future<void> _saveGoal() async {
    final currentUser = UserSession.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se encontró el usuario logueado."),
        ),
      );
      return;
    }

    if (_selectedGoal == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedUser = User(
      id: currentUser.id,
      name: currentUser.name,
      surname: currentUser.surname,
      email: currentUser.email,
      birthDate: currentUser.birthDate,
      objective: _selectedGoal,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Objetivo guardado correctamente."),
        ),
      );

      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error al guardar el objetivo."),
      ),
    );
  }

  Widget _buildGoalTile(GoalOption goal) {
    final isSelected = _selectedGoal == goal.value;

    return InkWell(
      onTap: _isSaving
          ? null
          : () {
              setState(() {
                _selectedGoal = goal.value;
              });
            },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                goal.icon,
                color: isSelected
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Objetivo nutricional"),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "¿Cuál es tu objetivo principal?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Podés cambiarlo más adelante desde tu perfil.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            ..._goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGoalTile(goal),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedGoal == null || _isSaving
                    ? null
                    : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

class GoalOption {
  final String title;
  final String description;
  final String value;
  final IconData icon;

  const GoalOption({
    required this.title,
    required this.description,
    required this.value,
    required this.icon,
  });
}