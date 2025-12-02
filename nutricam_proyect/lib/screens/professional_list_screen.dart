import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/screens/calendar_screen.dart';
import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/profile_screen.dart';
import 'package:nutricam_proyect/screens/scan_plate_screen.dart';

class ProfessionalListScreen extends StatefulWidget {
  final String userName;
  const ProfessionalListScreen({super.key, required this.userName});

  @override
  State<ProfessionalListScreen> createState() => _ProfessionalListScreenState();
}

class _ProfessionalListScreenState extends State<ProfessionalListScreen> {
  final List<Professional> professionals = [
    Professional(
      name: 'Dr. Carlos Mendoza',
      specialty: 'Deportivo',
      rating: 4.9,
      reviews: 156,
      availability: 'Disponible',
    ),
    Professional(
      name: 'Dra. Ana Rodríguez',
      specialty: 'Nutrición Clínica',
      rating: 5.0,
      reviews: 120,
      availability: 'Disponible',
    ),
    Professional(
      name: 'Dr. Luis Fernández',
      specialty: 'Nutrición Vegetariana',
      rating: 4.8,
      reviews: 98,
      availability: 'Disponible en 30 min',
    ),
    Professional(
      name: 'Dra. Patricia Gómez',
      specialty: 'Móvil',
      rating: null,
      reviews: null,
      availability: 'Disponible',
    ),
  ];

  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(userName: widget.userName)),
      );
    } else if (index == 0){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userName: widget.userName)),
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
    return Scaffold(
      appBar: AppBar(title: Text('Profesionales Disponibles')),
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
      body: ListView.builder(
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          final prof = professionals[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(
                  prof.name.contains('Dra.')
                      ? 'assets/images/femaleDoctor.png'
                      : 'assets/images/maleDoctor.png',
                ),
              ),
              title: Text(prof.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prof.specialty),
                  if (prof.rating != null && prof.reviews != null)
                    Text('★ ${prof.rating} (${prof.reviews})'),
                  Text(prof.availability),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // Acción de videollamada
                },
                child: Text('Videollamada'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Professional {
  final String name;
  final String specialty;
  final double? rating;
  final int? reviews;
  final String availability;

  Professional({
    required this.name,
    required this.specialty,
    this.rating,
    this.reviews,
    required this.availability,
  });
}
