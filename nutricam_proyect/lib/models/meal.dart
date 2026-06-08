class Meal {
  final int? id;
  final int userId;
  final String mealName;
  final String mealType;
  final String quantity;
  final String? mealDate;
  final String registrationSource;
  final List<String> foodGroups;
  final int? recommendedPlateId;

  Meal({
    this.id,
    required this.userId,
    required this.mealName,
    required this.mealType,
    required this.quantity,
    this.mealDate,
    this.registrationSource = 'MANUAL',
    this.foodGroups = const [],
    this.recommendedPlateId,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    final dynamic recommendedPlateJson =
        json['recommendedPlate'];

    int? parsedRecommendedPlateId;

    if (recommendedPlateJson is Map<String, dynamic>) {
      parsedRecommendedPlateId =
          recommendedPlateJson['id'] as int?;
    }

    final dynamic foodGroupsJson = json['foodGroups'];

    final List<String> parsedFoodGroups;

    if (foodGroupsJson is List) {
      parsedFoodGroups = foodGroupsJson
          .whereType<String>()
          .toList();
    } else {
      parsedFoodGroups = [];
    }

    return Meal(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      mealName: json['mealName'] as String,
      mealType: json['mealType'] as String,
      quantity: json['quantity'] as String,
      mealDate: json['mealDate'] as String?,
      registrationSource:
          json['registrationSource'] as String? ??
              'MANUAL',
      foodGroups: parsedFoodGroups,
      recommendedPlateId: parsedRecommendedPlateId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mealName': mealName,
      'mealType': mealType,
      'quantity': quantity,
      'registrationSource': registrationSource,
      'foodGroups': foodGroups,
      if (recommendedPlateId != null)
        'recommendedPlateId': recommendedPlateId,
    };
  }
}