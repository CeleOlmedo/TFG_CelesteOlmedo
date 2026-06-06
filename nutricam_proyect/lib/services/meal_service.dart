import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/models/meal.dart';

class MealService {
  static const String baseUrl = "http://10.0.2.2:8080";

  static Future<bool> createMeal(Meal meal) async {
    final url = Uri.parse("$baseUrl/meals");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(meal.toJson()),
    );

    return response.statusCode == 200;
  }

  static Future<List<Meal>> getMealsByUser(int userId) async {
    final url = Uri.parse("$baseUrl/meals/user/$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Meal.fromJson(json)).toList();
    }

    return [];
  }
}