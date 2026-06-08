import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/core/api_config.dart';
import 'package:nutricam_proyect/models/user.dart';

class UserService {
  UserService._();

  static const Duration _requestTimeout = Duration(seconds: 8);

  static Future<bool> updateUser(User user) async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/update/${user.id}',
    );

    try {
      final http.Response response = await http
          .put(
            url,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(user.toJson()),
          )
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } on FormatException {
      return false;
    }
  }
}