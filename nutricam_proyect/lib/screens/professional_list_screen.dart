import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/widgets/app_bottom_navigation.dart';

class ProfessionalListScreen extends StatelessWidget {
  final String userName;

  const ProfessionalListScreen({
    super.key,
    required this.userName,
  });

  static const List<Professional> professionals = [
    Professional(
      name: 'Dr. Carlos Mendoza',
      specialty: 'Nutrición deportiva',
      rating: 4.9,
      reviews: 156,
      availability: 'Disponible',
    ),
    Professional(
      name: 'Dra. Ana Rodríguez',
      specialty: 'Nutrición clínica',
      rating: 5.0,
      reviews: 120,
      availability: 'Disponible',
    ),
    Professional(
      name: 'Dr. Luis Fernández',
      specialty: 'Nutrición vegetariana',
      rating: 4.8,
      reviews: 98,
      availability: 'Disponible en 30 min',
    ),
    Professional(
      name: 'Dra. Patricia Gómez',
      specialty: 'Atención móvil',
      availability: 'Disponible',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profesionales'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        userName: userName,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: professionals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final professional = professionals[index];

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(
                      professional.name.contains('Dra.')
                          ? 'assets/images/femaleDoctor.png'
                          : 'assets/images/maleDoctor.png',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professional.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          professional.specialty,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (professional.rating != null &&
                            professional.reviews != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '★ ${professional.rating} '
                            '(${professional.reviews} reseñas)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          professional.availability,
                          style: TextStyle(
                            fontSize: 12,
                            color: professional.availability == 'Disponible'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La consulta profesional se implementará próximamente.',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Consultar',
                      style: TextStyle(
                        color: AppColors.backgroundComponent,
                      ),
                    ),
                  ),
                ],
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

  const Professional({
    required this.name,
    required this.specialty,
    required this.availability,
    this.rating,
    this.reviews,
  });
}