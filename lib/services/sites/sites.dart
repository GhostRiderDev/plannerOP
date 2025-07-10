import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:plannerop/core/network/httpClient.dart';

class SiteService {
  final ApiClient _apiClient = ApiClient();

  // Método para obtener todos los sitios
  Future<List<dynamic>> getAllSites() async {
    try {
      final response = await _apiClient.get('/site');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error al obtener sitios: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de conexión al obtener sitios: $e');
      return [];
    }
  }
}
