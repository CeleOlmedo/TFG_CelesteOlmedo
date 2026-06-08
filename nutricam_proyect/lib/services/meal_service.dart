import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/core/api_config.dart';
import 'package:nutricam_proyect/models/meal.dart';

class MealService {
  MealService._();

  static const Duration _requestTimeout = Duration(seconds: 8);

  static Future<bool> createMeal(Meal meal) async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/meals',
    );

    try {
      final http.Response response = await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(meal.toJson()),
          )
          .timeout(_requestTimeout);

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } on FormatException {
      return false;
    }
  }

  static Future<List<Meal>> getMealsByUser(int userId) async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/meals/user/$userId',
    );

    try {
      final http.Response response = await http
          .get(url)
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo consultar el historial. '
          'Código: ${response.statusCode}',
        );
      }

      final dynamic decodedBody = jsonDecode(response.body);

      if (decodedBody is! List) {
        throw const FormatException(
          'La respuesta del historial no es válida.',
        );
      }

      return decodedBody
          .map(
            (dynamic item) => Meal.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw Exception(
        'No se pudo establecer conexión con el servidor.',
      );
    }
  }
}