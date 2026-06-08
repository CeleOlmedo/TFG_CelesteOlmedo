class RecommendedPlate {
  final int id;
  final String name;
  final String description;
  final String portion;
  final int? estimatedCalories;
  final double? estimatedProtein;
  final int? preparationTimeMinutes;
  final String processingLevel;
  final bool active;
  final String source;
  final List<String> allowedMealTypes;
  final List<String> foodGroups;

  const RecommendedPlate({
    required this.id,
    required this.name,
    required this.description,
    required this.portion,
    required this.estimatedCalories,
    required this.estimatedProtein,
    required this.preparationTimeMinutes,
    required this.processingLevel,
    required this.active,
    required this.source,
    required this.allowedMealTypes,
    required this.foodGroups,
  });

  factory RecommendedPlate.fromJson(Map<String, dynamic> json) {
    return RecommendedPlate(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      portion: json['portion'] as String,
      estimatedCalories: json['estimatedCalories'] as int?,
      estimatedProtein: _parseDouble(json['estimatedProtein']),
      preparationTimeMinutes: json['preparationTimeMinutes'] as int?,
      processingLevel: json['processingLevel'] as String,
      active: json['active'] as bool,
      source: json['source'] as String,
      allowedMealTypes: _parseStringList(json['allowedMealTypes']),
      foodGroups: _parseStringList(json['foodGroups']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value.map((item) => item.toString()).toList();
  }
}