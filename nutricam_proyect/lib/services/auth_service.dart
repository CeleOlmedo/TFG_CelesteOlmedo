import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/core/api_config.dart';
import 'package:nutricam_proyect/models/user.dart';

enum LoginStatus {
  success,
  userNotFound,
  invalidPassword,
  invalidRequest,
  serverError,
}

class LoginResult {
  final LoginStatus status;
  final User? user;

  const LoginResult({
    required this.status,
    this.user,
  });
}

enum RegisterStatus {
  success,
  emailAlreadyExists,
  invalidRequest,
  serverError,
}

class RegisterResult {
  final RegisterStatus status;
  final User? user;

  const RegisterResult({
    required this.status,
    this.user,
  });
}

class AuthService {
  AuthService._();

  static const Duration _requestTimeout = Duration(seconds: 8);

  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/login',
    );

    final http.Response response = await http
        .post(
          url,
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(_requestTimeout);

    switch (response.statusCode) {
      case 200:
        if (response.body.isEmpty) {
          throw const FormatException(
            'La respuesta del inicio de sesión está vacía.',
          );
        }

        final dynamic decodedBody = jsonDecode(response.body);

        if (decodedBody is! Map<String, dynamic>) {
          throw const FormatException(
            'La respuesta del inicio de sesión '
            'no contiene un usuario válido.',
          );
        }

        return LoginResult(
          status: LoginStatus.success,
          user: User.fromJson(decodedBody),
        );

      case 400:
        return const LoginResult(
          status: LoginStatus.invalidRequest,
        );

      case 401:
        return const LoginResult(
          status: LoginStatus.invalidPassword,
        );

      case 404:
        return const LoginResult(
          status: LoginStatus.userNotFound,
        );

      default:
        return const LoginResult(
          status: LoginStatus.serverError,
        );
    }
  }

  static Future<RegisterResult> register({
    required String name,
    required String surname,
    required String birthDate,
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/register',
    );

    final http.Response response = await http
        .post(
          url,
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'surname': surname,
            'birthDate': birthDate,
            'email': email,
            'password': password,
          }),
        )
        .timeout(_requestTimeout);

    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) {
          throw const FormatException(
            'La respuesta del registro está vacía.',
          );
        }

        final dynamic decodedBody = jsonDecode(response.body);

        if (decodedBody is! Map<String, dynamic>) {
          throw const FormatException(
            'La respuesta del registro '
            'no contiene un usuario válido.',
          );
        }

        return RegisterResult(
          status: RegisterStatus.success,
          user: User.fromJson(decodedBody),
        );

      case 400:
        return const RegisterResult(
          status: RegisterStatus.invalidRequest,
        );

      case 409:
        return const RegisterResult(
          status: RegisterStatus.emailAlreadyExists,
        );

      default:
        return const RegisterResult(
          status: RegisterStatus.serverError,
        );
    }
  }
}