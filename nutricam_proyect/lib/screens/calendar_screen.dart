import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/professional_list_screen.dart';
import 'package:nutricam_proyect/screens/profile_screen.dart';
import 'package:nutricam_proyect/screens/scan_plate_screen.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final String userName;
  const CalendarScreen({super.key, required this.userName});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final int _progress = 5; // ejemplo: 5 días completados

  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userName: widget.userName),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfessionalListScreen(userName: widget.userName),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanPlateScreen(userName: widget.userName),
        ),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userName: widget.userName),
        ),
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
      appBar: AppBar(
        title: Text('Calendario Nutricional'),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progreso semanal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progreso Semanal', style: TextStyle(fontSize: 16)),
                  Text('$_progress/7 días'),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progress / 7,
                color: AppColors.primary,
                backgroundColor: AppColors.background,
              ),
              SizedBox(height: 20),

              // Calendario
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mes',
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.backgroundComponentSelected,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                locale: 'es_ES',
              ),
              SizedBox(height: 20),

              // Recetas del día
              Text('Recetas para hoy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // En vez de Expanded+ListView, usamos Column directamente
              RecipeCard(
                title: 'Desayuno',
                items: ['Yogurt con frutas + 2 tostadas', 'Infusión o café'],
              ),
              RecipeCard(
                title: 'Almuerzo',
                items: [
                  'Pechuga de pollo a la plancha',
                  'Ensalada: hojas verdes, tomate, zanahoria, palta',
                  'Porción pequeña de arroz integral',
                ],
              ),
              RecipeCard(
                title: 'Merienda',
                items: ['(A definir)'],
              ),
              RecipeCard(
                title: 'Cena',
                items: ['(A definir)'],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const RecipeCard({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...items.map((item) => Text('• $item')),
          ],
        ),
      ),
    );
  }
}
