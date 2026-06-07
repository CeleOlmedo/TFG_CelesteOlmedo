import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/screens/edit_profile_screen.dart';
import 'package:nutricam_proyect/screens/goal_selection_screen.dart';
import 'package:nutricam_proyect/widgets/app_bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({
    super.key,
    required this.userName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) {
      return 0;
    }

    final parsedDate = DateTime.tryParse(birthDate);

    if (parsedDate == null) {
      return 0;
    }

    final today = DateTime.now();
    int age = today.year - parsedDate.year;

    final birthdayHasNotOccurred =
        today.month < parsedDate.month ||
        (today.month == parsedDate.month && today.day < parsedDate.day);

    if (birthdayHasNotOccurred) {
      age--;
    }

    return age;
  }

  String _formatObjective(String? objective) {
    if (objective == null || objective.isEmpty) {
      return "No configurado";
    }

    switch (objective) {
      case "BAJAR_PESO":
        return "Bajar de peso";
      case "MANTENER_PESO":
        return "Mantener el peso";
      case "GANAR_MASA":
        return "Ganar masa muscular";
      case "HABITOS_SALUDABLES":
        return "Incorporar hábitos saludables";
      default:
        return objective;
    }
  }

  Future<void> _openGoalSelection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GoalSelectionScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openEditProfile() async {
    final user = UserSession.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se encontró el usuario logueado."),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: user),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.currentUser;
    final age = _calculateAge(user?.birthDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 4,
        userName: widget.userName,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 68,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "${user?.name ?? ""} ${user?.surname ?? ""}".trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              user?.email ?? "",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mi objetivo",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatObjective(user?.objective),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openGoalSelection,
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(
                        user?.objective == null
                            ? "Configurar objetivo"
                            : "Cambiar objetivo",
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Información personal",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: "Nombre",
                    value: user?.name ?? "No informado",
                  ),

                  const Divider(height: 26),

                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: "Apellido",
                    value: user?.surname ?? "No informado",
                  ),

                  const Divider(height: 26),

                  _buildInfoRow(
                    icon: Icons.cake_outlined,
                    label: "Edad",
                    value: age > 0 ? "$age años" : "No informada",
                  ),

                  const Divider(height: 26),

                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: "Correo",
                    value: user?.email ?? "No informado",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openEditProfile,
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.backgroundComponent,
                ),
                label: Text(
                  "Editar perfil",
                  style: TextStyle(
                    color: AppColors.backgroundComponent,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}