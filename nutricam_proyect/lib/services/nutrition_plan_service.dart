import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/core/api_config.dart';
import 'package:nutricam_proyect/models/daily_recommendation.dart';
import 'package:nutricam_proyect/models/nutrition_plan.dart';

enum NutritionPlanStatusResult {
  success,
  notFound,
  userNotFound,
  objectiveRequired,
  invalidResponse,
  serverError,
  connectionError,
  timeout,
}

class NutritionPlanResult {
  final NutritionPlanStatusResult status;
  final NutritionPlan? plan;
  final String? message;

  const NutritionPlanResult({
    required this.status,
    this.plan,
    this.message,
  });

  bool get isSuccess {
    return status == NutritionPlanStatusResult.success &&
        plan != null;
  }
}

enum DailyRecommendationStatusResult {
  success,
  planNotFound,
  invalidResponse,
  serverError,
  connectionError,
  timeout,
}

class DailyRecommendationResult {
  final DailyRecommendationStatusResult status;
  final DailyRecommendation? recommendation;
  final String? message;

  const DailyRecommendationResult({
    required this.status,
    this.recommendation,
    this.message,
  });

  bool get isSuccess {
    return status ==
            DailyRecommendationStatusResult.success &&
        recommendation != null;
  }
}

class NutritionPlanService {
  NutritionPlanService._();

  static const Duration _planRequestTimeout =
      Duration(seconds: 8);

  static const Duration _recommendationRequestTimeout =
      Duration(seconds: 40);

  static Future<NutritionPlanResult> getActivePlan(
    int userId,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}'
      '/nutrition-plans/active/user/$userId',
    );

    try {
      final response = await http
          .get(url)
          .timeout(_planRequestTimeout);

      return _handlePlanResponse(
        response,
        operation: _PlanOperation.get,
      );
    } on TimeoutException {
      return const NutritionPlanResult(
        status: NutritionPlanStatusResult.timeout,
        message:
            'El servidor tardó demasiado en responder.',
      );
    } on SocketException {
      return const NutritionPlanResult(
        status:
            NutritionPlanStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } on http.ClientException {
      return const NutritionPlanResult(
        status:
            NutritionPlanStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } catch (_) {
      return const NutritionPlanResult(
        status: NutritionPlanStatusResult.invalidResponse,
        message:
            'La respuesta del servidor no tiene un formato válido.',
      );
    }
  }

  static Future<NutritionPlanResult> generateWeeklyPlan(
    int userId,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}'
      '/nutrition-plans/generate/user/$userId',
    );

    try {
      final response = await http
          .post(url)
          .timeout(_planRequestTimeout);

      return _handlePlanResponse(
        response,
        operation: _PlanOperation.generate,
      );
    } on TimeoutException {
      return const NutritionPlanResult(
        status: NutritionPlanStatusResult.timeout,
        message:
            'La generación del plan tardó demasiado.',
      );
    } on SocketException {
      return const NutritionPlanResult(
        status:
            NutritionPlanStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } on http.ClientException {
      return const NutritionPlanResult(
        status:
            NutritionPlanStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } catch (_) {
      return const NutritionPlanResult(
        status: NutritionPlanStatusResult.invalidResponse,
        message:
            'La respuesta del servidor no tiene un formato válido.',
      );
    }
  }


  static Future<NutritionPlanResult> replacePlanMeal(
    int userId,
    int mealId,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}'
      '/nutrition-plans/active/user/$userId'
      '/meals/$mealId/replace',
    );

    try {
      final response = await http
          .put(url)
          .timeout(_planRequestTimeout);

      return _handlePlanResponse(
        response,
        operation: _PlanOperation.replace,
      );
    } on TimeoutException {
      return const NutritionPlanResult(
        status: NutritionPlanStatusResult.timeout,
        message:
            'El reemplazo del plato tardó demasiado.',
      );
    } on SocketException {
      return const NutritionPlanResult(
        status:
            NutritionPlanStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } on http.ClientException {
      return const NutritionPlanResult(
        status:
            NutritionPlanStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } catch (_) {
      return const NutritionPlanResult(
        status: NutritionPlanStatusResult.invalidResponse,
        message:
            'La respuesta del servidor no tiene un formato válido.',
      );
    }
  }

  static Future<DailyRecommendationResult>
      generateOrGetDailyRecommendation(
    int userId,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}'
      '/nutrition-plans/daily-recommendation/user/$userId',
    );

    try {
      final response = await http
          .post(url)
          .timeout(_recommendationRequestTimeout);

      switch (response.statusCode) {
        case 200:
          return _parseDailyRecommendationResponse(
            response,
          );

        case 404:
          return DailyRecommendationResult(
            status:
                DailyRecommendationStatusResult.planNotFound,
            message: _extractServerMessage(
              response,
              fallback:
                  'No existe un plan activo para el día de hoy.',
            ),
          );

        default:
          return DailyRecommendationResult(
            status:
                DailyRecommendationStatusResult.serverError,
            message: _extractServerMessage(
              response,
              fallback:
                  'No se pudo generar la recomendación diaria. '
                  'Código: ${response.statusCode}.',
            ),
          );
      }
    } on TimeoutException {
      return const DailyRecommendationResult(
        status: DailyRecommendationStatusResult.timeout,
        message:
            'La recomendación está tardando más de lo esperado.',
      );
    } on SocketException {
      return const DailyRecommendationResult(
        status:
            DailyRecommendationStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } on http.ClientException {
      return const DailyRecommendationResult(
        status:
            DailyRecommendationStatusResult.connectionError,
        message:
            'No se pudo establecer conexión con el servidor.',
      );
    } catch (_) {
      return const DailyRecommendationResult(
        status:
            DailyRecommendationStatusResult.invalidResponse,
        message:
            'La respuesta de la recomendación no tiene '
            'un formato válido.',
      );
    }
  }

  static NutritionPlanResult _handlePlanResponse(
    http.Response response, {
    required _PlanOperation operation,
  }) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return _parseSuccessfulPlanResponse(response);

      case 400:
        if (operation == _PlanOperation.replace) {
          return NutritionPlanResult(
            status: NutritionPlanStatusResult.serverError,
            message: _extractServerMessage(
              response,
              fallback:
                  'No se pudo reemplazar el plato seleccionado.',
            ),
          );
        }

        return const NutritionPlanResult(
          status: NutritionPlanStatusResult.objectiveRequired,
          message:
              'Debés seleccionar un objetivo antes de generar tu plan.',
        );

      case 404:
        if (operation == _PlanOperation.get) {
          return NutritionPlanResult(
            status: NutritionPlanStatusResult.notFound,
            message: _extractServerMessage(
              response,
              fallback:
                  'Todavía no existe un plan activo.',
            ),
          );
        }

        if (operation == _PlanOperation.replace) {
          return NutritionPlanResult(
            status: NutritionPlanStatusResult.notFound,
            message: _extractServerMessage(
              response,
              fallback:
                  'No se encontró el plan o el plato seleccionado.',
            ),
          );
        }

        return NutritionPlanResult(
          status:
              NutritionPlanStatusResult.userNotFound,
          message: _extractServerMessage(
            response,
            fallback:
                'No se encontró el usuario solicitado.',
          ),
        );

      default:
        return NutritionPlanResult(
          status: NutritionPlanStatusResult.serverError,
          message: _extractServerMessage(
            response,
            fallback:
                'No se pudo completar la operación. '
                'Código: ${response.statusCode}.',
          ),
        );
    }
  }

  static NutritionPlanResult
      _parseSuccessfulPlanResponse(
    http.Response response,
  ) {
    final dynamic decodedBody =
        jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      return const NutritionPlanResult(
        status: NutritionPlanStatusResult.invalidResponse,
        message:
            'El servidor no devolvió un plan válido.',
      );
    }

    final plan = NutritionPlan.fromJson(decodedBody);

    return NutritionPlanResult(
      status: NutritionPlanStatusResult.success,
      plan: plan,
    );
  }

  static DailyRecommendationResult
      _parseDailyRecommendationResponse(
    http.Response response,
  ) {
    final dynamic decodedBody =
        jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      return const DailyRecommendationResult(
        status:
            DailyRecommendationStatusResult.invalidResponse,
        message:
            'El servidor no devolvió una recomendación válida.',
      );
    }

    final recommendation =
        DailyRecommendation.fromJson(decodedBody);

    if (!recommendation.wasGenerated) {
      return const DailyRecommendationResult(
        status:
            DailyRecommendationStatusResult.invalidResponse,
        message:
            'La recomendación recibida está incompleta.',
      );
    }

    return DailyRecommendationResult(
      status: DailyRecommendationStatusResult.success,
      recommendation: recommendation,
    );
  }

  static String _extractServerMessage(
    http.Response response, {
    required String fallback,
  }) {
    if (response.body.trim().isEmpty) {
      return fallback;
    }

    try {
      final dynamic decodedBody =
          jsonDecode(response.body);

      if (decodedBody is Map<String, dynamic>) {
        final dynamic message =
            decodedBody['message'] ??
                decodedBody['error'] ??
                decodedBody['detail'];

        if (message != null &&
            message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      return fallback;
    }

    return fallback;
  }
}

enum _PlanOperation {
  get,
  generate,
  replace,
}