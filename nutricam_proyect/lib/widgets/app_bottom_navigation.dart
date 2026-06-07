import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/meal_records_screen.dart';
import 'package:nutricam_proyect/screens/plates_screen.dart';
import 'package:nutricam_proyect/screens/professional_list_screen.dart';
import 'package:nutricam_proyect/screens/profile_screen.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final String userName;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.userName,
  });

  void _navigateTo(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;

    switch (index) {
      case 0:
        screen = HomeScreen(userName: userName);
        break;
      case 1:
        screen = PlatesScreen(userName: userName);
        break;
      case 2:
        screen = ProfessionalListScreen(userName: userName);
        break;
      case 3:
        screen = MealRecordsScreen(userName: userName);
        break;
      case 4:
        screen = ProfileScreen(userName: userName);
        break;
      default:
        screen = HomeScreen(userName: userName);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _navigateTo(context, index),
      backgroundColor: AppColors.secondary,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey.shade600,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Inicio",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: "Platos",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services),
          label: "Profesionales",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: "Registros",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: "Perfil",
        ),
      ],
    );
  }
}