import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/core/api_config.dart';
import 'package:nutricam_proyect/models/meal_image_analysis.dart';
import 'package:http_parser/http_parser.dart';

enum MealImageResultStatus {
  success,
  invalidRequest,
  userNotFound,
  alreadyConfirmed,
  serviceUnavailable,
  invalidResponse,
  connectionError,
  timeout,
  serverError,
}

class MealImageResult {
  final MealImageResultStatus status;
  final MealImageAnalysis? analysis;
  final String? message;

  const MealImageResult({
    required this.status,
    this.analysis,
    this.message,
  });

  bool get isSuccess {
    return status == MealImageResultStatus.success &&
        analysis != null;
  }
}

class MealImageService {
  MealImageService._();

  static const Duration _analysisTimeout =
      Duration(seconds: 75);

  static const Duration _confirmationTimeout =
      Duration(seconds: 12);

  static Future<MealImageResult> analyzeImage({
    required int userId,
    required File image,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/meal-images/analyze',
    );

    try {
      final request = http.MultipartRequest(
        'POST',
        url,
      );

      request.fields['userId'] = userId.toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: _getImageContentType(image.path),
        ),
      );

      final streamedResponse = await request
          .send()
          .timeout(_analysisTimeout);

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      return _handleResponse(response);
    } on TimeoutException {
      return const MealImageResult(
        status: MealImageResultStatus.timeout,
        message:
            'El análisis está tardando más de lo esperado.',
      );
    } on SocketException {
      return const MealImageResult(
        status: MealImageResultStatus.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } on http.ClientException {
      return const MealImageResult(
        status: MealImageResultStatus.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } catch (_) {
      return const MealImageResult(
        status: MealImageResultStatus.invalidResponse,
        message:
            'No se pudo procesar la respuesta del análisis.',
      );
    }
  }

  static Future<MealImageResult> confirmAnalysis({
    required int analysisId,
    required int userId,
    required String mealName,
    required String mealType,
    required String quantity,
    required DateTime mealDate,
    required Set<String> foodGroups,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}'
      '/meal-images/$analysisId/confirm',
    );

    final body = jsonEncode({
      'userId': userId,
      'mealName': mealName.trim(),
      'mealType': mealType,
      'quantity': quantity.trim(),
      'mealDate': _formatDate(mealDate),
      'foodGroups': foodGroups.toList(),
    });

    try {
      final response = await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(_confirmationTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      return const MealImageResult(
        status: MealImageResultStatus.timeout,
        message:
            'La confirmación tardó demasiado.',
      );
    } on SocketException {
      return const MealImageResult(
        status: MealImageResultStatus.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } on http.ClientException {
      return const MealImageResult(
        status: MealImageResultStatus.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } catch (_) {
      return const MealImageResult(
        status: MealImageResultStatus.invalidResponse,
        message:
            'No se pudo procesar la respuesta del servidor.',
      );
    }
  }

  static MealImageResult _handleResponse(
    http.Response response,
  ) {
    switch (response.statusCode) {
      case 200:
        return _parseSuccessfulResponse(response);

      case 400:
        return MealImageResult(
          status: MealImageResultStatus.invalidRequest,
          message: _extractMessage(
            response,
            fallback:
                'Los datos enviados no son válidos.',
          ),
        );

      case 404:
        return MealImageResult(
          status: MealImageResultStatus.userNotFound,
          message: _extractMessage(
            response,
            fallback:
                'No se encontró el usuario o el análisis.',
          ),
        );

      case 409:
        return MealImageResult(
          status: MealImageResultStatus.alreadyConfirmed,
          message: _extractMessage(
            response,
            fallback:
                'Este análisis ya fue confirmado.',
          ),
        );

      case 503:
        return MealImageResult(
          status:
              MealImageResultStatus.serviceUnavailable,
          message: _extractMessage(
            response,
            fallback:
                'No se pudo analizar la imagen en este momento.',
          ),
        );

      default:
        return MealImageResult(
          status: MealImageResultStatus.serverError,
          message: _extractMessage(
            response,
            fallback:
                'Ocurrió un error en el servidor. '
                'Código: ${response.statusCode}.',
          ),
        );
    }
  }

  static MealImageResult _parseSuccessfulResponse(
    http.Response response,
  ) {
    final dynamic decodedBody = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decodedBody is! Map<String, dynamic>) {
      return const MealImageResult(
        status: MealImageResultStatus.invalidResponse,
        message:
            'El servidor no devolvió un análisis válido.',
      );
    }

    final analysis = MealImageAnalysis.fromJson(
      decodedBody,
    );

    return MealImageResult(
      status: MealImageResultStatus.success,
      analysis: analysis,
    );
  }

  static MediaType _getImageContentType(String path) {
    final extension = path
        .split('.')
        .last
        .toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');

      case 'png':
        return MediaType('image', 'png');

      case 'webp':
        return MediaType('image', 'webp');

      default:
        throw const FormatException(
          'El formato de la imagen no es compatible.',
        );
    }
  }

  static String _extractMessage(
    http.Response response, {
    required String fallback,
  }) {
    if (response.bodyBytes.isEmpty) {
      return fallback;
    }

    try {
      final dynamic decodedBody = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decodedBody is Map<String, dynamic>) {
        final dynamic message =
            decodedBody['message'] ??
            decodedBody['detail'];

        if (message != null &&
            message.toString().trim().isNotEmpty) {
          return message.toString().trim();
        }

        final dynamic error = decodedBody['error'];

        if (error != null &&
            error.toString().trim().isNotEmpty &&
            error.toString() != 'Bad Request' &&
            error.toString() != 'Not Found' &&
            error.toString() != 'Service Unavailable') {
          return error.toString().trim();
        }
      }
    } catch (_) {
      return fallback;
    }

    return fallback;
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}