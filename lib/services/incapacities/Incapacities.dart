import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/incapacity.dart';
import 'package:plannerop/core/network/httpClient.dart';
import 'package:plannerop/utils/date.dart';

class IncapacityService {
  final ApiClient _apiClient = ApiClient();
  Future<bool> registerIncapacity(Incapacity incapacity) async {
    try {
      var url = '/inability';
      var response = await _apiClient.post(
        url,
        body: incapacity.toJson(),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error en registerIncapacity: $e');
      return false;
    }
  }

  //  método para buscar incapacidades con filtros
  Future<List<Incapacity>> searchIncapacities({
    int? workerId,
    DateTime? dateDisableStart,
    DateTime? dateDisableEnd,
    List<String>? types,
    List<String>? causes,
  }) async {
    try {
      // Construir la URL con parámetros de consulta
      String baseUrl = '/inability/search/filters';
      List<String> queryParams = [];

      if (workerId != null) {
        queryParams.add('id_worker=$workerId');
      }

      if (dateDisableStart != null) {
        queryParams.add('dateDisableStart=${formatDate(dateDisableStart)}');
      }

      if (dateDisableEnd != null) {
        queryParams.add('dateDisableEnd=${formatDate(dateDisableEnd)}');
      }

      if (types != null && types.isNotEmpty) {
        queryParams
            .add('type=${types.join('%2C%20')}'); // URL encoding para comas
      }

      if (causes != null && causes.isNotEmpty) {
        queryParams
            .add('cause=${causes.join('%2C%20')}'); // URL encoding para comas
      }

      String url = baseUrl;
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      var response = await _apiClient.get(
        url,
      );

      debugPrint(
          'Search Incapacities API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((json) => Incapacity.fromJson(json)).toList();
      } else {
        debugPrint('Error al buscar incapacidades: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en searchIncapacities: $e');
      return [];
    }
  }
}
