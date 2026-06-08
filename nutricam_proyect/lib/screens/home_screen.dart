import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/models/meal.dart';
import 'package:nutricam_proyect/models/nutrition_plan.dart';
import 'package:nutricam_proyect/screens/meal_records_screen.dart';
import 'package:nutricam_proyect/services/meal_service.dart';
import 'package:nutricam_proyect/services/nutrition_plan_service.dart';
import 'package:nutricam_proyect/widgets/app_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({
    super.key,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isGeneratingRecommendation = false;

  String? _errorMessage;
  NutritionPlan? _activePlan;
  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final currentUser = UserSession.currentUser;
    final userId = currentUser?.id;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se encontró el usuario de la sesión.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        NutritionPlanService.getActivePlan(userId),
        MealService.getMealsByUser(userId),
      ]);

      final planResult = results[0] as NutritionPlanResult;
      final meals = results[1] as List<Meal>;

      if (!mounted) {
        return;
      }

      NutritionPlan? plan;

      if (planResult.status ==
          NutritionPlanStatusResult.success) {
        plan = planResult.plan;
      } else if (planResult.status !=
          NutritionPlanStatusResult.notFound) {
        throw Exception(
          planResult.message ??
              'No se pudo cargar el plan activo.',
        );
      }

      setState(() {
        _activePlan = plan;
        _meals = meals;
        _isLoading = false;
      });

      final today = plan?.today;

      if (today != null &&
          !today.hasGeneratedRecommendation) {
        await _generateDailyRecommendation(userId);
      }
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = exception
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _generateDailyRecommendation(
    int userId,
  ) async {
    if (_isGeneratingRecommendation) {
      return;
    }

    setState(() {
      _isGeneratingRecommendation = true;
    });

    final result = await NutritionPlanService
        .generateOrGetDailyRecommendation(userId);

    if (!mounted) {
      return;
    }

    if (result.status ==
        DailyRecommendationStatusResult.success) {
      final refreshedPlanResult =
          await NutritionPlanService.getActivePlan(userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isGeneratingRecommendation = false;

        if (refreshedPlanResult.status ==
            NutritionPlanStatusResult.success) {
          _activePlan = refreshedPlanResult.plan;
        }
      });

      return;
    }

    setState(() {
      _isGeneratingRecommendation = false;
    });
  }

  void _openMealRecords() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MealRecordsScreen(
          userName: widget.userName,
        ),
      ),
    );
  }

  List<Meal> get _todayMeals {
    final now = DateTime.now();

    return _meals.where((meal) {
      if (meal.mealDate == null) {
        return false;
      }

      final mealDate = DateTime.tryParse(meal.mealDate!);

      if (mealDate == null) {
        return false;
      }

      return mealDate.year == now.year &&
          mealDate.month == now.month &&
          mealDate.day == now.day;
    }).toList();
  }

  String get _objectiveLabel {
    final objective =
        UserSession.currentUser?.objective;

    switch (objective) {
      case 'BAJAR_PESO':
        return 'Bajar de peso';
      case 'MANTENER_PESO':
        return 'Mantener el peso';
      case 'GANAR_MASA':
        return 'Ganar masa muscular';
      case 'HABITOS_SALUDABLES':
        return 'Mejorar hábitos saludables';
      default:
        return 'Sin objetivo seleccionado';
    }
  }

  NutritionPlanDay? get _todayPlanDay {
    return _activePlan?.today;
  }

  String? get _todayRecommendation {
    return _todayPlanDay?.dailyRecommendation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        userName: widget.userName,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 220),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.error_outline,
            size: 52,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadHomeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '¡Hola, ${widget.userName}! 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        _buildSummaryCard(),
        const SizedBox(height: 28),
        const Text(
          'Recomendación de hoy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildRecommendationCard(),
        const SizedBox(height: 28),
        const Text(
          'Registro de comidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildMealRecordsCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu objetivo actual',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _objectiveLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.restaurant_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_todayMeals.length} '
                '${_todayMeals.length == 1 ? 'comida registrada' : 'comidas registradas'} hoy',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    if (_activePlan == null) {
      return _buildInformationContainer(
        icon: Icons.calendar_today_outlined,
        text:
            'Todavía no tenés un plan activo. Generalo desde la sección Platos.',
      );
    }

    if (_todayPlanDay == null) {
      return _buildInformationContainer(
        icon: Icons.event_busy_outlined,
        text:
            'El plan activo no contiene información para el día de hoy.',
      );
    }

    if (_isGeneratingRecommendation) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Generando tu recomendación personalizada...',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final recommendation = _todayRecommendation;

    if (recommendation == null ||
        recommendation.trim().isEmpty) {
      return _buildInformationContainer(
        icon: Icons.lightbulb_outline,
        text:
            'La recomendación de hoy todavía no está disponible.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        recommendation,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildMealRecordsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _todayMeals.isEmpty
                ? 'Todavía no registraste comidas hoy.'
                : 'Registraste ${_todayMeals.length} '
                    '${_todayMeals.length == 1 ? 'comida' : 'comidas'} hoy.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMealRecords,
              icon: Icon(
                Icons.restaurant_menu,
                color: AppColors.backgroundComponent,
              ),
              label: Text(
                'Ir a mis registros',
                style: TextStyle(
                  color: AppColors.backgroundComponent,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationContainer({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}