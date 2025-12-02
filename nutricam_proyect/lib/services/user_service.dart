import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/components/user.dart';

class UserService {
  static const String baseUrl = "http://10.0.2.2:8080"; // Android emulator

  static Future<bool> updateUser(User user) async {
    final url = Uri.parse("$baseUrl/update/${user.id}");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );

    return response.statusCode == 200;
  }
}
