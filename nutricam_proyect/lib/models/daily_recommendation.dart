class DailyRecommendation {
  final int planDayId;
  final DateTime planDate;
  final String recommendation;
  final String status;
  final String method;
  final DateTime? generatedAt;

  const DailyRecommendation({
    required this.planDayId,
    required this.planDate,
    required this.recommendation,
    required this.status,
    required this.method,
    required this.generatedAt,
  });

  factory DailyRecommendation.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyRecommendation(
      planDayId: _parseRequiredInt(
        json['planDayId'],
        fieldName: 'planDayId',
      ),
      planDate: _parseRequiredDate(
        json['planDate'],
        fieldName: 'planDate',
      ),
      recommendation:
          json['recommendation']?.toString().trim() ?? '',
      status: json['status']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      generatedAt: _parseOptionalDateTime(
        json['generatedAt'],
      ),
    );
  }

  bool get wasGenerated {
    return status == 'GENERATED' &&
        recommendation.isNotEmpty;
  }

  bool get wasGeneratedWithAi {
    return method == 'AI';
  }

  bool get wasGeneratedWithFallback {
    return method == 'RULES_FALLBACK';
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
}