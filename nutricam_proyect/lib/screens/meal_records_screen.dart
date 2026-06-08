import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/models/meal.dart';
import 'package:nutricam_proyect/screens/goal_selection_screen.dart';
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
  bool _hasLoadError = false;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  List<Meal> get _filteredMeals {
    final selectedDate = _selectedDate;

    if (selectedDate == null) {
      return _meals;
    }

    return _meals.where((meal) {
      final mealDateText = meal.mealDate;

      if (mealDateText == null || mealDateText.isEmpty) {
        return false;
      }

      final mealDate = DateTime.tryParse(mealDateText);

      if (mealDate == null) {
        return false;
      }

      return DateUtils.isSameDay(mealDate, selectedDate);
    }).toList();
  }

  Future<void> _selectDate() async {
  final now = DateTime.now();

  final selectedDate = await showDatePicker(
    context: context,
    initialDate: _selectedDate ?? now,
    firstDate: DateTime(now.year - 5),
    lastDate: now,
    helpText: 'Seleccionar fecha',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
  );

  if (selectedDate == null || !mounted) {
    return;
  }

  setState(() {
    _selectedDate = selectedDate;
  });
}

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _loadMeals() async {
    final currentUser = UserSession.currentUser;

    if (currentUser?.id == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _meals = [];
        _isLoading = false;
        _hasLoadError = true;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasLoadError = false;
      });
    }

    try {
      final meals = await MealService.getMealsByUser(
        currentUser!.id!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _meals = meals;
        _hasLoadError = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasLoadError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _ensureUserHasGoal() async {
    final currentUser = UserSession.currentUser;
    final objective = currentUser?.objective?.trim();

    if (objective != null && objective.isNotEmpty) {
      return true;
    }

    final shouldSelectGoal = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Objetivo requerido'),
          content: const Text(
            'Para registrar una comida primero tenés que '
            'seleccionar un objetivo nutricional.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Seleccionar objetivo'),
            ),
          ],
        );
      },
    );

    if (shouldSelectGoal != true || !mounted) {
      return false;
    }

    final wasUpdated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const GoalSelectionScreen(),
      ),
    );

    if (!mounted) {
      return false;
    }

    final updatedObjective =
        UserSession.currentUser?.objective?.trim();

    return wasUpdated == true &&
        updatedObjective != null &&
        updatedObjective.isNotEmpty;
  }

  Future<void> _openManualRegistration() async {
    final canRegister = await _ensureUserHasGoal();

    if (!canRegister || !mounted) {
      return;
    }

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
    final canRegister = await _ensureUserHasGoal();

    if (!canRegister || !mounted) {
      return;
    }

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
      case 'desayuno':
        return Icons.wb_sunny_outlined;
      case 'almuerzo':
        return Icons.wb_sunny;
      case 'merienda':
        return Icons.local_cafe_outlined;
      case 'cena':
        return Icons.nightlight_outlined;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 44,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar el historial.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verificá la conexión con el servidor e intentá nuevamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadMeals,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'Todavía no registraste comidas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Podés agregar una manualmente o escanear tu plato.',
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

  Widget _buildMealHistory() {
    final visibleMeals = _filteredMeals;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleMeals.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final meal = visibleMeals[index];

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

  Widget _buildDateFilter() {
    final selectedDate = _selectedDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por fecha',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedDate == null
                      ? 'Mostrando todos los registros'
                      : _formatDate(selectedDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (selectedDate != null)
            IconButton(
              tooltip: 'Quitar filtro',
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.close),
            ),
          IconButton(
            tooltip: 'Seleccionar fecha',
            onPressed: _selectDate,
            icon: const Icon(Icons.edit_calendar_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMealsForDateState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 42,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay comidas registradas en esta fecha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedDate == null
                ? ''
                : _formatDate(_selectedDate!),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _clearDateFilter,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Mostrar todos'),
          ),
        ],
      ),
    );
  }

  Widget _buildMealList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasLoadError) {
      return _buildErrorState();
    }

    if (_meals.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredMeals.isEmpty) {
      return _buildNoMealsForDateState();
    }

    return _buildMealHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Registros'),
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
                'Historial de comidas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Consultá y registrá tus comidas diarias.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _buildDateFilter(),
              const SizedBox(height: 16),
              _buildMealList(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openManualRegistration,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Registrar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
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
                        'Escanear',
                        style: TextStyle(
                          color: AppColors.backgroundComponent,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
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

  String _selectedMealType = 'Desayuno';
  bool _isSaving = false;

  final Set<String> _selectedFoodGroups = {};

  final List<String> _mealTypes = [
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Snack',
  ];

  final Map<String, String> _foodGroupLabels = {
    'FRUTAS': 'Frutas',
    'VERDURAS': 'Verduras',
    'LEGUMBRES': 'Legumbres',
    'CEREALES_Y_DERIVADOS': 'Cereales y derivados',
    'PAPA_BATATA_MANDIOCA': 'Papa, batata y mandioca',
    'LECHE_YOGUR_Y_QUESO': 'Leche, yogur y queso',
    'CARNES': 'Carnes',
    'PESCADOS': 'Pescados',
    'HUEVOS': 'Huevos',
    'FRUTOS_SECOS_Y_SEMILLAS':
        'Frutos secos y semillas',
    'ACEITES_Y_GRASAS': 'Aceites y grasas',
    'AZUCARES_Y_DULCES': 'Azúcares y dulces',
  };

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
          content: Text(
            'No se encontró el usuario logueado.',
          ),
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
      registrationSource: 'MANUAL',
      foodGroups: _selectedFoodGroups.toList(),
    );

    final success = await MealService.createMeal(meal);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo registrar la comida.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        keyboardHeight + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Registrar comida',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de comida',
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
                  onChanged: _isSaving
                      ? null
                      : (value) {
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
                  enabled: !_isSaving,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '¿Qué comiste?',
                    hintText:
                        'Ej.: ensalada, arroz con pollo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresá el nombre de la comida';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad o porción',
                    hintText:
                        'Ej.: 1 unidad, 200 g, 1 plato',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresá la cantidad consumida';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Grupos alimentarios presentes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Seleccioná todos los grupos que formen parte de la comida.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                FormField<Set<String>>(
                  initialValue: _selectedFoodGroups,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccioná al menos un grupo alimentario';
                    }

                    return null;
                  },
                  builder: (formFieldState) {
                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _foodGroupLabels.entries
                              .map((entry) {
                            final isSelected =
                                _selectedFoodGroups
                                    .contains(entry.key);

                            return FilterChip(
                              label: Text(entry.value),
                              selected: isSelected,
                              onSelected: _isSaving
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedFoodGroups
                                              .add(entry.key);
                                        } else {
                                          _selectedFoodGroups
                                              .remove(entry.key);
                                        }
                                      });

                                      formFieldState.didChange(
                                        Set<String>.from(
                                          _selectedFoodGroups,
                                        ),
                                      );
                                    },
                            );
                          }).toList(),
                        ),
                        if (formFieldState.hasError) ...[
                          const SizedBox(height: 8),
                          Text(
                            formFieldState.errorText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isSaving ? null : _saveMeal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Guardar comida',
                            style: TextStyle(
                              color: AppColors
                                  .backgroundComponent,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}