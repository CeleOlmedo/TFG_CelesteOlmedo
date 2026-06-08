class NutritionPlan {
  final int id;
  final int userId;
  final DateTime startDate;
  final DateTime endDate;
  final String userObjective;
  final String status;
  final String generationMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<NutritionPlanDay> days;

  const NutritionPlan({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.userObjective,
    required this.status,
    required this.generationMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.days,
  });

  factory NutritionPlan.fromJson(
    Map<String, dynamic> json,
  ) {
    return NutritionPlan(
      id: _parseRequiredInt(
        json['id'],
        fieldName: 'id',
      ),
      userId: _parseRequiredInt(
        json['userId'],
        fieldName: 'userId',
      ),
      startDate: _parseRequiredDate(
        json['startDate'],
        fieldName: 'startDate',
      ),
      endDate: _parseRequiredDate(
        json['endDate'],
        fieldName: 'endDate',
      ),
      userObjective:
          json['userObjective']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      generationMethod:
          json['generationMethod']?.toString() ?? '',
      createdAt: _parseOptionalDateTime(
        json['createdAt'],
      ),
      updatedAt: _parseOptionalDateTime(
        json['updatedAt'],
      ),
      days: _parseDays(json['days']),
    );
  }

  NutritionPlanDay? getDayForDate(DateTime date) {
    for (final day in days) {
      if (_isSameDate(day.planDate, date)) {
        return day;
      }
    }

    return null;
  }

  NutritionPlanDay? get today {
    return getDayForDate(DateTime.now());
  }

  bool get isActive {
    return status == 'ACTIVE';
  }

  static List<NutritionPlanDay> _parseDays(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    final days = value
        .whereType<Map<String, dynamic>>()
        .map(NutritionPlanDay.fromJson)
        .toList();

    days.sort(
      (first, second) => first.displayOrder.compareTo(
        second.displayOrder,
      ),
    );

    return days;
  }

  static int _parseRequiredInt(
    dynamic value, {
    required String fieldName,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final parsedValue = int.tryParse(
      value?.toString() ?? '',
    );

    if (parsedValue == null) {
      throw FormatException(
        'El campo $fieldName no contiene un entero válido.',
      );
    }

    return parsedValue;
  }

  static DateTime _parseRequiredDate(
    dynamic value, {
    required String fieldName,
  }) {
    final parsedDate = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (parsedDate == null) {
      throw FormatException(
        'El campo $fieldName no contiene una fecha válida.',
      );
    }

    return parsedDate;
  }

  static DateTime? _parseOptionalDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class NutritionPlanDay {
  final int id;
  final DateTime planDate;
  final int displayOrder;
  final String? dailyRecommendation;
  final String recommendationStatus;
  final String? recommendationMethod;
  final DateTime? recommendationGeneratedAt;
  final List<NutritionPlanMeal> meals;

  const NutritionPlanDay({
    required this.id,
    required this.planDate,
    required this.displayOrder,
    required this.dailyRecommendation,
    required this.recommendationStatus,
    required this.recommendationMethod,
    required this.recommendationGeneratedAt,
    required this.meals,
  });

  factory NutritionPlanDay.fromJson(
    Map<String, dynamic> json,
  ) {
    final recommendation =
        json['dailyRecommendation']?.toString().trim();

    return NutritionPlanDay(
      id: NutritionPlan._parseRequiredInt(
        json['id'],
        fieldName: 'day.id',
      ),
      planDate: NutritionPlan._parseRequiredDate(
        json['planDate'],
        fieldName: 'day.planDate',
      ),
      displayOrder: NutritionPlan._parseRequiredInt(
        json['displayOrder'],
        fieldName: 'day.displayOrder',
      ),
      dailyRecommendation:
          recommendation == null || recommendation.isEmpty
              ? null
              : recommendation,
      recommendationStatus:
          json['recommendationStatus']?.toString() ??
              'PENDING',
      recommendationMethod:
          json['recommendationMethod']?.toString(),
      recommendationGeneratedAt:
          NutritionPlan._parseOptionalDateTime(
        json['recommendationGeneratedAt'],
      ),
      meals: _parseMeals(json['meals']),
    );
  }

  bool get hasGeneratedRecommendation {
    return recommendationStatus == 'GENERATED' &&
        dailyRecommendation != null;
  }

  NutritionPlanMeal? getMealByType(
    String mealType,
  ) {
    for (final meal in meals) {
      if (meal.mealType == mealType) {
        return meal;
      }
    }

    return null;
  }

  static List<NutritionPlanMeal> _parseMeals(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    final meals = value
        .whereType<Map<String, dynamic>>()
        .map(NutritionPlanMeal.fromJson)
        .toList();

    meals.sort(
      (first, second) => first.displayOrder.compareTo(
        second.displayOrder,
      ),
    );

    return meals;
  }
}

class NutritionPlanMeal {
  final int id;
  final String mealType;
  final int recommendedPlateId;
  final String plateName;
  final String description;
  final String portion;
  final int? estimatedCalories;
  final double? estimatedProtein;
  final int? preparationTimeMinutes;
  final String processingLevel;
  final List<String> foodGroups;
  final String reason;
  final int displayOrder;

  const NutritionPlanMeal({
    required this.id,
    required this.mealType,
    required this.recommendedPlateId,
    required this.plateName,
    required this.description,
    required this.portion,
    required this.estimatedCalories,
    required this.estimatedProtein,
    required this.preparationTimeMinutes,
    required this.processingLevel,
    required this.foodGroups,
    required this.reason,
    required this.displayOrder,
  });

  factory NutritionPlanMeal.fromJson(
    Map<String, dynamic> json,
  ) {
    return NutritionPlanMeal(
      id: NutritionPlan._parseRequiredInt(
        json['id'],
        fieldName: 'meal.id',
      ),
      mealType: json['mealType']?.toString() ?? '',
      recommendedPlateId:
          NutritionPlan._parseRequiredInt(
        json['recommendedPlateId'],
        fieldName: 'meal.recommendedPlateId',
      ),
      plateName: json['plateName']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      portion: json['portion']?.toString() ?? '',
      estimatedCalories: _parseOptionalInt(
        json['estimatedCalories'],
      ),
      estimatedProtein: _parseOptionalDouble(
        json['estimatedProtein'],
      ),
      preparationTimeMinutes: _parseOptionalInt(
        json['preparationTimeMinutes'],
      ),
      processingLevel:
          json['processingLevel']?.toString() ?? '',
      foodGroups: _parseStringList(
        json['foodGroups'],
      ),
      reason: json['reason']?.toString() ?? '',
      displayOrder: NutritionPlan._parseRequiredInt(
        json['displayOrder'],
        fieldName: 'meal.displayOrder',
      ),
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _parseOptionalDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static List<String> _parseStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString())
        .toList();
  }
}