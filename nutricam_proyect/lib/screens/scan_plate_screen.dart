import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/screens/calendar_screen.dart';
import 'dart:io';

import 'package:nutricam_proyect/screens/home_screen.dart';
import 'package:nutricam_proyect/screens/professional_list_screen.dart';
import 'package:nutricam_proyect/screens/profile_screen.dart';

class ScanPlateScreen extends StatefulWidget {
  final String userName;
  const ScanPlateScreen({super.key, required this.userName});

  @override
  State<ScanPlateScreen> createState() => _ScanPlateScreenState();
}

class _ScanPlateScreenState extends State<ScanPlateScreen> {
  File? _image;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // Aquí podrías enviar la imagen al backend o procesarla
    }
  }

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(userName: widget.userName,)),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfessionalListScreen(userName: widget.userName)),
      );
    } else if (index == 0){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userName: widget.userName)),
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
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: Text('Escanea tu plato'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Coloca el plato en el centro del marco',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.teal[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.camera_alt, size: 80, color: Colors.white),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: Icon(Icons.camera),
              label: Text('Tomar Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            if (_image != null) ...[
              SizedBox(height: 30),
              Text('Foto tomada:', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Image.file(_image!, width: 200),
            ],
          ],
        ),
      ),
    );
  }
}
