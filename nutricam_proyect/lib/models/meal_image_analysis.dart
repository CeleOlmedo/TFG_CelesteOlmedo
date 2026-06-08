class MealImageAnalysis {
  final int id;
  final int userId;
  final String suggestedMealName;
  final List<String> detectedFoods;
  final Set<String> foodGroups;
  final String status;
  final String warning;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final int? mealId;

  const MealImageAnalysis({
    required this.id,
    required this.userId,
    required this.suggestedMealName,
    required this.detectedFoods,
    required this.foodGroups,
    required this.status,
    required this.warning,
    required this.createdAt,
    required this.confirmedAt,
    required this.mealId,
  });

  factory MealImageAnalysis.fromJson(
    Map<String, dynamic> json,
  ) {
    return MealImageAnalysis(
      id: _parseRequiredInt(
        json['id'],
        'id',
      ),
      userId: _parseRequiredInt(
        json['userId'],
        'userId',
      ),
      suggestedMealName:
          json['suggestedMealName']?.toString().trim() ?? '',
      detectedFoods: _parseStringList(
        json['detectedFoods'],
      ),
      foodGroups: _parseStringList(
        json['foodGroups'],
      ).toSet(),
      status: json['status']?.toString() ?? '',
      warning: json['warning']?.toString().trim() ?? '',
      createdAt: _parseRequiredDateTime(
        json['createdAt'],
        'createdAt',
      ),
      confirmedAt: _parseOptionalDateTime(
        json['confirmedAt'],
      ),
      mealId: _parseOptionalInt(
        json['mealId'],
      ),
    );
  }

  bool get isAnalyzed {
    return status == 'ANALYZED';
  }

  bool get isConfirmed {
    return status == 'CONFIRMED';
  }

  static int _parseRequiredInt(
    dynamic value,
    String fieldName,
  ) {
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
        'El campo $fieldName no contiene un número válido.',
      );
    }

    return parsedValue;
  }

  static int? _parseOptionalInt(
    dynamic value,
  ) {
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

  static DateTime _parseRequiredDateTime(
    dynamic value,
    String fieldName,
  ) {
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

  static List<String> _parseStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}