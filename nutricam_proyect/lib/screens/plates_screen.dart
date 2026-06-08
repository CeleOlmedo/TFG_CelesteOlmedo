import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/models/recommended_plate.dart';
import 'package:nutricam_proyect/services/recommended_plate_service.dart';
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
  String _selectedCategory = 'Todos';

  bool _isLoading = true;
  String? _errorMessage;
  List<RecommendedPlate> _plates = [];

  static const List<String> _categories = [
    'Todos',
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlates();
  }

  Future<void> _loadPlates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plates = await RecommendedPlateService.getActivePlates();

      if (!mounted) {
        return;
      }

      setState(() {
        _plates = plates;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudieron cargar los platos recomendados. '
            'Verificá la conexión con el servidor e intentá nuevamente.';
      });
    }
  }

  List<RecommendedPlate> get _filteredPlates {
    if (_selectedCategory == 'Todos') {
      return _plates;
    }

    final selectedMealType = _categoryToMealType(_selectedCategory);

    return _plates.where((plate) {
      return plate.allowedMealTypes.contains(selectedMealType);
    }).toList();
  }

  String _categoryToMealType(String category) {
    switch (category) {
      case 'Desayuno':
        return 'DESAYUNO';
      case 'Almuerzo':
        return 'ALMUERZO';
      case 'Merienda':
        return 'MERIENDA';
      case 'Cena':
        return 'CENA';
      default:
        return '';
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _showPlateDetails(RecommendedPlate plate) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 22),
                _buildDetailRow(
                  icon: Icons.restaurant_outlined,
                  label: 'Porción orientativa',
                  value: plate.portion,
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Calorías estimadas',
                  value: _formatCalories(plate.estimatedCalories),
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.fitness_center_outlined,
                  label: 'Proteínas estimadas',
                  value: _formatProtein(plate.estimatedProtein),
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Tiempo de preparación',
                  value: _formatPreparationTime(
                    plate.preparationTimeMinutes,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.eco_outlined,
                  label: 'Nivel de procesamiento',
                  value: _formatProcessingLevel(
                    plate.processingLevel,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Momentos recomendados',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildValueChips(
                  plate.allowedMealTypes
                      .map(_formatMealType)
                      .toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Grupos alimentarios',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildValueChips(
                  plate.foodGroups
                      .map(_formatFoodGroup)
                      .toList(),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundComponent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValueChips(List<String> values) {
    if (values.isEmpty) {
      return Text(
        'Sin información disponible',
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade200,
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) {
              _selectCategory(category);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlateCard(RecommendedPlate plate) {
    return InkWell(
      onTap: () {
        _showPlateDetails(plate);
      },
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
                color: AppColors.secondary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.restaurant,
                size: 34,
                color: AppColors.primary,
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
                    runSpacing: 6,
                    children: [
                      _PlateInfo(
                        icon: Icons.local_fire_department_outlined,
                        text: _formatCalories(
                          plate.estimatedCalories,
                        ),
                      ),
                      _PlateInfo(
                        icon: Icons.fitness_center_outlined,
                        text: _formatProtein(
                          plate.estimatedProtein,
                        ),
                      ),
                      _PlateInfo(
                        icon: Icons.schedule_outlined,
                        text: _formatPreparationTime(
                          plate.preparationTimeMinutes,
                        ),
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

  Widget _buildLoadingState() {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 58,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'No se pudieron cargar los platos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPlates,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundComponent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String message,
  }) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_food_outlined,
                size: 58,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatesContent() {
    final filteredPlates = _filteredPlates;

    return Expanded(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPlates,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text(
              'Sugerencias para vos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Explorá opciones del catálogo de NutriCam, '
              'organizadas según los distintos momentos del día.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Los valores nutricionales son estimativos y estas '
              'sugerencias no reemplazan la consulta profesional.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 22),
            _buildCategorySelector(),
            const SizedBox(height: 22),
            if (filteredPlates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 52),
                child: Column(
                  children: [
                    Icon(
                      Icons.no_food_outlined,
                      size: 52,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No hay platos disponibles para esta categoría.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(
                filteredPlates.length,
                (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == filteredPlates.length - 1
                          ? 0
                          : 14,
                    ),
                    child: _buildPlateCard(
                      filteredPlates[index],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatCalories(int? calories) {
    if (calories == null) {
      return 'Sin dato';
    }

    return '$calories kcal';
  }

  String _formatProtein(double? protein) {
    if (protein == null) {
      return 'Sin dato';
    }

    final formattedProtein = protein == protein.roundToDouble()
        ? protein.toInt().toString()
        : protein.toStringAsFixed(1);

    return '$formattedProtein g';
  }

  String _formatPreparationTime(int? minutes) {
    if (minutes == null) {
      return 'Sin dato';
    }

    return '$minutes min';
  }

  String _formatProcessingLevel(String value) {
    switch (value) {
      case 'MINIMAMENTE_PROCESADO':
        return 'Mínimamente procesado';
      case 'PROCESADO':
        return 'Procesado';
      case 'ULTRAPROCESADO':
        return 'Ultraprocesado';
      default:
        return _formatEnumValue(value);
    }
  }

  String _formatMealType(String value) {
    switch (value) {
      case 'DESAYUNO':
        return 'Desayuno';
      case 'ALMUERZO':
        return 'Almuerzo';
      case 'MERIENDA':
        return 'Merienda';
      case 'CENA':
        return 'Cena';
      case 'COLACION':
        return 'Colación';
      default:
        return _formatEnumValue(value);
    }
  }

  String _formatFoodGroup(String value) {
    switch (value) {
      case 'FRUTAS':
        return 'Frutas';
      case 'VERDURAS':
        return 'Verduras';
      case 'LEGUMBRES':
        return 'Legumbres';
      case 'CEREALES_Y_DERIVADOS':
        return 'Cereales y derivados';
      case 'PAPA_BATATA_MANDIOCA':
        return 'Papa, batata y mandioca';
      case 'LECHE_YOGUR_Y_QUESO':
        return 'Leche, yogur y queso';
      case 'CARNES':
        return 'Carnes';
      case 'PESCADOS':
        return 'Pescados';
      case 'HUEVOS':
        return 'Huevos';
      case 'FRUTOS_SECOS_Y_SEMILLAS':
        return 'Frutos secos y semillas';
      case 'ACEITES_Y_GRASAS':
        return 'Aceites y grasas';
      case 'AZUCARES_Y_DULCES':
        return 'Azúcares y dulces';
      default:
        return _formatEnumValue(value);
    }
  }

  String _formatEnumValue(String value) {
    final words = value.toLowerCase().split('_');

    if (words.isEmpty) {
      return value;
    }

    final formatted = words.join(' ');

    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Platos recomendados'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        userName: widget.userName,
      ),
      body: Column(
        children: [
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_plates.isEmpty)
            _buildEmptyState(
              message:
                  'Por el momento no hay platos disponibles en el catálogo.',
            )
          else
            _buildPlatesContent(),
        ],
      ),
    );
  }
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