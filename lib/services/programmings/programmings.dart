import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/core/network/httpClient.dart';

class ProgrammingsService {
  final ApiClient _apiClient = ApiClient();

  ///  Actualizar estado de una programación
  Future<bool> updateProgrammingStatus(
      int programmingId, String newStatus, BuildContext context) async {
    try {
      final response = await _apiClient.patch(
        '/client-programming/$programmingId',
        body: {
          'status': newStatus,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Error al actualizar programación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error al actualizar estado de programación: $e');
      return false;
    }
  }

  /// Método para obtener las programaciones por fecha
  /// param date: Fecha en formato 'YYYY-MM-DD'
  Future<List<Programming>> getProgrammingsByDate(String date) async {
    try {
      final response = await _apiClient.get(
        '/client-programming/filtered?dateStart=$date',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Programming.fromJson(item)).toList();
      } else if (response.statusCode == 403) {
        // Manejar el caso de acceso denegado
        throw Exception('Acceso denegado');
      } else if (response.statusCode == 404) {
        // Manejar el caso de no encontrado
        return [];
      } else {
        throw Exception('Error al obtener programaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener una programación específica por ID
  Future<Programming?> getProgrammingById(
      int programmingId, BuildContext context) async {
    try {
      final response = await _apiClient.get(
        '/client-programming/$programmingId',
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return Programming.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('Programación $programmingId no encontrada');
        return null;
      } else {
        throw Exception('Error al obtener programación');
      }
    } catch (e) {
      debugPrint('Error al obtener programación por ID: $e');
      return null;
    }
  }
}
