import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nutricam_proyect/models/recommended_plate.dart';
import 'package:nutricam_proyect/core/api_config.dart';

class RecommendedPlateService {

  static const Duration _requestTimeout = Duration(seconds: 8);

  static Future<List<RecommendedPlate>> getActivePlates() async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/recommended-plates',
    );

    try {
      final http.Response response = await http
          .get(url)
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudieron obtener los platos recomendados. '
          'Código: ${response.statusCode}',
        );
      }

      final dynamic decodedBody = jsonDecode(response.body);

      if (decodedBody is! List) {
        throw const FormatException(
          'La respuesta del servidor no contiene una lista de platos.',
        );
      }

      return decodedBody
          .map(
            (dynamic item) => RecommendedPlate.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder.',
      );
    }
  }

  static Future<RecommendedPlate> getPlateById(int id) async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/recommended-plates/$id',
    );

    try {
      final http.Response response = await http
          .get(url)
          .timeout(_requestTimeout);

      if (response.statusCode == 404) {
        throw Exception(
          'El plato solicitado no existe o no está disponible.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo obtener el plato recomendado. '
          'Código: ${response.statusCode}',
        );
      }

      final dynamic decodedBody = jsonDecode(response.body);

      if (decodedBody is! Map<String, dynamic>) {
        throw const FormatException(
          'La respuesta del servidor no contiene un plato válido.',
        );
      }

      return RecommendedPlate.fromJson(decodedBody);
    } on TimeoutException {
      throw Exception(
        'El servidor tardó demasiado en responder.',
      );
    }
  }
}