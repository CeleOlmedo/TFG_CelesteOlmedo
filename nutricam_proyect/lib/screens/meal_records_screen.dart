import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/models/meal.dart';
import 'package:nutricam_proyect/screens/scan_plate_screen.dart';
import 'package:nutricam_proyect/services/meal_service.dart';
import 'package:nutricam_proyect/widgets/app_bottom_navigation.dart';

class MealRecordsScreen extends StatefulWidget {
  final String userName;

  const MealRecordsScreen({
    super.key,
    required this.userName,
  });

  @override
  State<MealRecordsScreen> createState() => _MealRecordsScreenState();
}

class _MealRecordsScreenState extends State<MealRecordsScreen> {
  List<Meal> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final currentUser = UserSession.currentUser;

    if (currentUser?.id == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    final meals = await MealService.getMealsByUser(currentUser!.id!);

    if (!mounted) return;

    setState(() {
      _meals = meals.reversed.toList();
      _isLoading = false;
    });
  }

  Future<void> _openManualRegistration() async {
    final wasSaved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ManualMealForm(),
    );

    if (wasSaved == true) {
      await _loadMeals();
    }
  }

  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPlateScreen(
          userName: widget.userName,
        ),
      ),
    );

    await _loadMeals();
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case "desayuno":
        return Icons.wb_sunny_outlined;
      case "almuerzo":
        return Icons.wb_sunny;
      case "merienda":
        return Icons.local_cafe_outlined;
      case "cena":
        return Icons.nightlight_outlined;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildMealList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 42,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              "Todavía no registraste comidas.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Podés agregar una manualmente o escanear tu plato.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _meals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final meal = _meals[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMealIcon(meal.mealType),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealType,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal.mealName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal.quantity,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (meal.mealDate != null)
                Text(
                  meal.mealDate!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Mis Registros"),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        userName: widget.userName,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMeals,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Historial de comidas",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Consultá y registrá tus comidas diarias.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              _buildMealList(),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openManualRegistration,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Registrar"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openScanner,
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.backgroundComponent,
                      ),
                      label: Text(
                        "Escanear",
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualMealForm extends StatefulWidget {
  const _ManualMealForm();

  @override
  State<_ManualMealForm> createState() => _ManualMealFormState();
}

class _ManualMealFormState extends State<_ManualMealForm> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedMealType = "Desayuno";
  bool _isSaving = false;

  final List<String> _mealTypes = [
    "Desayuno",
    "Almuerzo",
    "Merienda",
    "Cena",
    "Snack",
  ];

  @override
  void dispose() {
    _mealNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = UserSession.currentUser;

    if (currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se encontró el usuario logueado."),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final meal = Meal(
      userId: currentUser!.id!,
      mealName: _mealNameController.text.trim(),
      mealType: _selectedMealType,
      quantity: _quantityController.text.trim(),
    );

    final success = await MealService.createMeal(meal);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo registrar la comida."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, keyboardHeight + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Registrar comida",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: "Tipo de comida",
                  border: OutlineInputBorder(),
                ),
                items: _mealTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMealType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _mealNameController,
                decoration: const InputDecoration(
                  labelText: "¿Qué comiste?",
                  hintText: "Ej.: manzana, ensalada, arroz con pollo",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Ingresá el nombre de la comida";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: "Cantidad o porción",
                  hintText: "Ej.: 1 unidad, 200 g, 1 plato",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Ingresá la cantidad consumida";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMeal,
                  style: ElevatedButton.styleFrom(
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
                      : Text(
                          "Guardar comida",
                          style: TextStyle(
                            color: AppColors.backgroundComponent,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}