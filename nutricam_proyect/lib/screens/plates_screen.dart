import 'package:flutter/material.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/models/nutrition_plan.dart';
import 'package:nutricam_proyect/services/nutrition_plan_service.dart';
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
  bool _isLoadingPlan = true;
  bool _isGeneratingPlan = false;
  bool _isGeneratingRecommendation = false;

  String? _recommendationErrorMessage;
  String? _planErrorMessage;
  NutritionPlan? _activePlan;

  @override
  void initState() {
    super.initState();
    _loadActivePlan();
  }

  Future<void> _refreshPlan() async {
    await _loadActivePlan();
  }

  Future<void> _loadActivePlan({
    bool generateRecommendation = true,
  }) async {
    final currentUser = UserSession.currentUser;

    if (currentUser?.id == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPlan = false;
        _activePlan = null;
        _planErrorMessage =
            'No se encontró el usuario de la sesión.';
      });

      return;
    }

    setState(() {
      _isLoadingPlan = true;
      _planErrorMessage = null;
    });

    final result = await NutritionPlanService.getActivePlan(
      currentUser!.id!,
    );

    if (!mounted) {
      return;
    }

    switch (result.status) {
      case NutritionPlanStatusResult.success:
        final plan = result.plan;

        setState(() {
          _activePlan = plan;
          _isLoadingPlan = false;
          _planErrorMessage = null;
        });

        final today = plan?.today;

        if (generateRecommendation &&
            today != null &&
            !today.hasGeneratedRecommendation) {
          await _generateDailyRecommendation(
            currentUser.id!,
          );
        }

        return;

      case NutritionPlanStatusResult.notFound:
        setState(() {
          _activePlan = null;
          _isLoadingPlan = false;
          _planErrorMessage = null;
        });
        return;

      case NutritionPlanStatusResult.connectionError:
      case NutritionPlanStatusResult.timeout:
      case NutritionPlanStatusResult.serverError:
      case NutritionPlanStatusResult.invalidResponse:
      case NutritionPlanStatusResult.userNotFound:
      case NutritionPlanStatusResult.objectiveRequired:
        setState(() {
          _activePlan = null;
          _isLoadingPlan = false;
          _planErrorMessage =
              result.message ?? 'No se pudo cargar el plan.';
        });
        return;
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
        _recommendationErrorMessage = null;
      });

      final result = await NutritionPlanService
          .generateOrGetDailyRecommendation(userId);

      if (!mounted) {
        return;
      }

      switch (result.status) {
        case DailyRecommendationStatusResult.success:
          setState(() {
            _isGeneratingRecommendation = false;
            _recommendationErrorMessage = null;
          });

          await _loadActivePlan(
            generateRecommendation: false,
          );
          return;

        case DailyRecommendationStatusResult.planNotFound:
        case DailyRecommendationStatusResult.invalidResponse:
        case DailyRecommendationStatusResult.serverError:
        case DailyRecommendationStatusResult.connectionError:
        case DailyRecommendationStatusResult.timeout:
          setState(() {
            _isGeneratingRecommendation = false;
            _recommendationErrorMessage =
                result.message ??
                'No se pudo obtener la recomendación diaria.';
          });
          return;
      }
    }

  Future<void> _generatePlan() async {
    final currentUser = UserSession.currentUser;

    if (currentUser?.id == null || _isGeneratingPlan) {
      return;
    }

    setState(() {
      _isGeneratingPlan = true;
      _planErrorMessage = null;
    });

    final result =
        await NutritionPlanService.generateWeeklyPlan(
      currentUser!.id!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isGeneratingPlan = false;
    });

    switch (result.status) {
      case NutritionPlanStatusResult.success:
      setState(() {
        _activePlan = result.plan;
        _planErrorMessage = null;
        _recommendationErrorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El plan semanal se generó correctamente.',
          ),
        ),
      );

      final generatedPlan = result.plan;
      final today = generatedPlan?.today;

      if (today != null &&
          !today.hasGeneratedRecommendation) {
        await _generateDailyRecommendation(
          currentUser.id!,
        );
      }

      return;

      case NutritionPlanStatusResult.objectiveRequired:
        setState(() {
          _planErrorMessage =
              result.message ??
              'Primero debés seleccionar un objetivo.';
        });
        return;

      case NutritionPlanStatusResult.userNotFound:
      case NutritionPlanStatusResult.connectionError:
      case NutritionPlanStatusResult.timeout:
      case NutritionPlanStatusResult.serverError:
      case NutritionPlanStatusResult.invalidResponse:
      case NutritionPlanStatusResult.notFound:
        setState(() {
          _planErrorMessage =
              result.message ??
              'No se pudo generar el plan semanal.';
        });
        return;
    }
  }

  Future<void> _confirmRegeneratePlan() async {
    if (_isGeneratingPlan) {
      return;
    }

    final shouldRegenerate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Regenerar plan'),
          content: const Text(
            'El plan actual será reemplazado por uno nuevo. '
            'El anterior quedará guardado como inactivo.',
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
              child: const Text('Regenerar'),
            ),
          ],
        );
      },
    );

    if (shouldRegenerate == true && mounted) {
      await _generatePlan();
    }
  }

  NutritionPlanDay? _getDisplayedPlanDay(
    NutritionPlan plan,
  ) {
    final today = plan.today;

    if (today != null) {
      return today;
    }

    if (plan.days.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final normalizedNow = DateTime(
      now.year,
      now.month,
      now.day,
    );

    for (final day in plan.days) {
      final normalizedDay = DateTime(
        day.planDate.year,
        day.planDate.month,
        day.planDate.day,
      );

      if (normalizedDay.isAfter(normalizedNow)) {
        return day;
      }
    }

    return plan.days.first;
  }

  void _showWeeklyPlan(NutritionPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    10,
                    10,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Plan semanal',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      28,
                    ),
                    itemCount: plan.days.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 14);
                    },
                    itemBuilder: (context, index) {
                      final day = plan.days[index];

                      return _buildWeeklyDayCard(day);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlanSection() {
    if (_isLoadingPlan) {
      return _buildPlanLoadingCard();
    }

    if (_planErrorMessage != null) {
      return _buildPlanErrorCard();
    }

    final plan = _activePlan;

    if (plan == null) {
      return _buildNoPlanCard();
    }

    final displayedDay = _getDisplayedPlanDay(plan);

    if (displayedDay == null) {
      return _buildInvalidPlanCard();
    }

    return _buildActivePlanCard(
      plan,
      displayedDay,
    );
  }

  Widget _buildPlanLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _planCardDecoration(),
      child: const Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Cargando tu plan semanal...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _planCardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar el plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _planErrorMessage ??
                'Ocurrió un error inesperado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loadActivePlan,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _planCardDecoration(),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Todavía no tenés un plan semanal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Generá una propuesta de siete días con '
            'desayuno, almuerzo, merienda y cena.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isGeneratingPlan ? null : _generatePlan,
              icon: _isGeneratingPlan
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGeneratingPlan
                    ? 'Generando plan...'
                    : 'Generar plan semanal',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.backgroundComponent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _planCardDecoration(),
      child: const Text(
        'El plan activo no contiene días disponibles.',
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActivePlanCard(
    NutritionPlan plan,
    NutritionPlanDay day,
  ) {
    final isToday = _isSameDate(
      day.planDate,
      DateTime.now(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _planCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? 'Mi plan de hoy'
                          : 'Próximo día del plan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatFullDate(day.planDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !_isGeneratingPlan,
                onSelected: (value) {
                  if (value == 'regenerate') {
                    _confirmRegeneratePlan();
                  }
                },
                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'regenerate',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 10),
                          Text('Regenerar plan'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(
            day.meals.length,
            (index) {
              final meal = day.meals[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index == day.meals.length - 1
                          ? 0
                          : 10,
                ),
                child: _buildPlanMealRow(meal),
              );
            },
          ),
          const SizedBox(height: 18),
          _buildDailyRecommendation(day),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showWeeklyPlan(plan);
                  },
                  icon: const Icon(
                    Icons.view_week_outlined,
                  ),
                  label: const Text('Ver semana'),
                ),
              ),
              if (_isGeneratingPlan) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecommendation(
    NutritionPlanDay day,
  ) {
    final recommendation = day.dailyRecommendation;

    if (_isGeneratingRecommendation) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 21,
              height: 21,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Generando tu recomendación personalizada...',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_recommendationErrorMessage != null &&
        (recommendation == null ||
            recommendation.trim().isEmpty)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.red.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 21,
                  color: Colors.red.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _recommendationErrorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                final userId =
                    UserSession.currentUser?.id;

                if (userId != null) {
                  _generateDailyRecommendation(userId);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (recommendation == null ||
        recommendation.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 21,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'La recomendación diaria está pendiente.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.primary,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanMealRow(
    NutritionPlanMeal meal,
  ) {
    return InkWell(
      onTap: () {
        _showPlanMealDetails(meal);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _getMealTypeIcon(meal.mealType),
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatMealType(meal.mealType),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.plateName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (meal.portion.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meal.portion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDayCard(
    NutritionPlanDay day,
  ) {
    final isToday = _isSameDate(
      day.planDate,
      DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday
              ? AppColors.primary
              : Colors.grey.shade200,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatFullDate(day.planDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Hoy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            day.meals.length,
            (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index == day.meals.length - 1
                          ? 0
                          : 8,
                ),
                child: _buildPlanMealRow(
                  day.meals[index],
                ),
              );
            },
          ),
          if (day.dailyRecommendation != null &&
              day.dailyRecommendation!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.dailyRecommendation!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _planCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  void _showPlanMealDetails(
    NutritionPlanMeal meal,
  ) {
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
            padding: const EdgeInsets.fromLTRB(
              24,
              12,
              24,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                const SizedBox(height: 22),
                Text(
                  _formatMealType(meal.mealType),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meal.plateName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (meal.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    meal.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildDetailRow(
                  icon: Icons.restaurant_outlined,
                  label: 'Porción orientativa',
                  value: meal.portion.isEmpty
                      ? 'Sin dato'
                      : meal.portion,
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon:
                      Icons.local_fire_department_outlined,
                  label: 'Calorías estimadas',
                  value: _formatCalories(
                    meal.estimatedCalories,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.fitness_center_outlined,
                  label: 'Proteínas estimadas',
                  value: _formatProtein(
                    meal.estimatedProtein,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Tiempo de preparación',
                  value: _formatPreparationTime(
                    meal.preparationTimeMinutes,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Motivo de la selección',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  meal.reason,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Grupos alimentarios',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                _buildValueChips(
                  meal.foodGroups
                      .map(_formatFoodGroup)
                      .toList(),
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
            color: AppColors.secondary.withValues(
              alpha: 0.35,
            ),
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

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Las recomendaciones brindadas por NutriCam '
              'son de carácter general y no reemplazan la '
              'consulta con un profesional de la nutrición.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'DESAYUNO':
        return Icons.wb_sunny_outlined;
      case 'ALMUERZO':
        return Icons.wb_sunny;
      case 'MERIENDA':
        return Icons.local_cafe_outlined;
      case 'CENA':
        return Icons.nightlight_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatFullDate(DateTime date) {
    const weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];

    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '${weekday[0].toUpperCase()}'
        '${weekday.substring(1)} '
        '${date.day} de $month';
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

    final formattedProtein =
        protein == protein.roundToDouble()
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
    if (value.isEmpty) {
      return value;
    }

    final formatted =
        value.toLowerCase().split('_').join(' ');

    if (formatted.isEmpty) {
      return value;
    }

    return '${formatted[0].toUpperCase()}'
        '${formatted.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi plan'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        userName: widget.userName,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshPlan,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            28,
          ),
          children: [
            const Text(
              'Tu planificación',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Consultá los platos sugeridos para cada día '
              'de tu semana.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            _buildPlanSection(),
            const SizedBox(height: 20),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }
}