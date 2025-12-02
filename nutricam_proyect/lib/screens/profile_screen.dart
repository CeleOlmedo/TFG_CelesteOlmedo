import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/screens/calendar_screen.dart';
import 'package:nutricam_proyect/screens/edit_profile_screen.dart';
import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/professional_list_screen.dart';
import 'package:nutricam_proyect/screens/scan_plate_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  const ProfileScreen({super.key, required this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _calcularEdad(String birthDate) {
    if (birthDate.isEmpty) return 0;
    final fecha = DateTime.parse(birthDate);
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad;
  }

  int _selectedIndex = 4;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userName: widget.userName)),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfessionalListScreen(userName: widget.userName),
        ),
      );
    } else if (index == 1){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ScanPlateScreen(userName: widget.userName)),
      );
    } else if (index == 3){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CalendarScreen(userName: widget.userName)),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.secondary,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Escanear",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "Profesionales",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Calendario",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Perfil",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(Icons.person, size: 100),
              ),
              SizedBox(height: 20),

              Text(
                "${user?.name} ${user?.surname}",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(user?.email ?? '', style: TextStyle(color: Colors.grey)),

              SizedBox(height: 30),

              Text(
                'Información Personal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              SizedBox(height: 30),

              ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: user!),
                  ),
                );
              },
              child: Text("Editar Perfil", style: TextStyle(color: Colors.white)),
            ),


              SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 1),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _infoRow(
                      'Edad',
                      '${_calcularEdad(user?.birthDate ?? "")} años',
                    ),
                    SizedBox(height: 5),
                    _infoRow('Peso', "null"),
                    SizedBox(height: 5),
                    _infoRow('Altura', "null"),
                    SizedBox(height: 5),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
