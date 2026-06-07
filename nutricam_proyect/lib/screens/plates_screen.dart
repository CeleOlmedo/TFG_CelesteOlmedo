import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/widgets/app_bottom_navigation.dart';

class PlatesScreen extends StatefulWidget {
  final String userName;

  const PlatesScreen({
    super.key,
    required this.userName,
  });

  @override
  State<PlatesScreen> createState() => _PlatesScreenState();
}

class _PlatesScreenState extends State<PlatesScreen> {
  String _selectedCategory = "Todos";

  final List<String> _categories = const [
    "Todos",
    "Desayuno",
    "Almuerzo",
    "Merienda",
    "Cena",
  ];

  final List<RecommendedPlate> _plates = const [
    RecommendedPlate(
      name: "Tostadas con palta y huevo",
      description: "Pan integral, palta y huevo.",
      category: "Desayuno",
      calories: 380,
      protein: 15,
      preparationTime: 10,
      icon: "🥑",
    ),
    RecommendedPlate(
      name: "Yogur con frutas y avena",
      description: "Yogur natural, banana, frutilla y avena.",
      category: "Merienda",
      calories: 280,
      protein: 12,
      preparationTime: 5,
      icon: "🥣",
    ),
    RecommendedPlate(
      name: "Ensalada criolla completa",
      description: "Tomate, cebolla, huevo y aceite de oliva.",
      category: "Almuerzo",
      calories: 320,
      protein: 18,
      preparationTime: 15,
      icon: "🥗",
    ),
    RecommendedPlate(
      name: "Guiso de lentejas",
      description: "Lentejas, zanahoria, papa y cebolla.",
      category: "Almuerzo",
      calories: 450,
      protein: 22,
      preparationTime: 45,
      icon: "🍲",
    ),
    RecommendedPlate(
      name: "Pollo con verduras al horno",
      description: "Pechuga de pollo, zapallo, batata y brócoli.",
      category: "Cena",
      calories: 520,
      protein: 38,
      preparationTime: 40,
      icon: "🍗",
    ),
  ];

  List<RecommendedPlate> get _filteredPlates {
    if (_selectedCategory == "Todos") {
      return _plates;
    }

    return _plates
        .where((plate) => plate.category == _selectedCategory)
        .toList();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _showPlateDetails(RecommendedPlate plate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    plate.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  plate.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plate.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.local_fire_department_outlined,
                  "Calorías",
                  "${plate.calories} kcal",
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.fitness_center_outlined,
                  "Proteínas",
                  "${plate.protein} g",
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.schedule_outlined,
                  "Tiempo estimado",
                  "${plate.preparationTime} minutos",
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Cerrar",
                      style: TextStyle(
                        color: AppColors.backgroundComponent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => _selectCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildPlateCard(RecommendedPlate plate) {
    return InkWell(
      onTap: () => _showPlateDetails(plate),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                plate.icon,
                style: const TextStyle(fontSize: 34),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plate.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    plate.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _PlateInfo(
                        icon: Icons.local_fire_department_outlined,
                        text: "${plate.calories} kcal",
                      ),
                      _PlateInfo(
                        icon: Icons.fitness_center_outlined,
                        text: "${plate.protein} g",
                      ),
                      _PlateInfo(
                        icon: Icons.schedule_outlined,
                        text: "${plate.preparationTime} min",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlates = _filteredPlates;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Platos recomendados"),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        userName: widget.userName,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sugerencias para vos",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Opciones basadas en una alimentación equilibrada y en las "
              "Guías Alimentarias para la Población Argentina.",
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 22),

            _buildCategorySelector(),

            const SizedBox(height: 22),

            if (filteredPlates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    "No hay platos disponibles para esta categoría.",
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredPlates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildPlateCard(filteredPlates[index]);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class RecommendedPlate {
  final String name;
  final String description;
  final String category;
  final int calories;
  final int protein;
  final int preparationTime;
  final String icon;

  const RecommendedPlate({
    required this.name,
    required this.description,
    required this.category,
    required this.calories,
    required this.protein,
    required this.preparationTime,
    required this.icon,
  });
}

class _PlateInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PlateInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}