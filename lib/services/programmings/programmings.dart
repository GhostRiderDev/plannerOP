import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/store/auth.dart';
import 'package:provider/provider.dart';

class ProgrammingsService {
  final String API_URL = dotenv.get('API_URL');

  ///  Actualizar estado de una programación
  Future<bool> updateProgrammingStatus(
      int programmingId, String newStatus, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }

      final response = await http.patch(
        Uri.parse('$API_URL/client-programming/$programmingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        // debugPrint(
        //     'Estado de programación $programmingId actualizado a $newStatus');
        return true;
      } else if (response.statusCode == 401) {
        authProvider.logout();
        throw Exception('Token no válido');
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
  Future<List<Programming>> getProgrammingsByDate(
      String date, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return [];
      }
      final response = await http.get(
        Uri.parse('$API_URL/client-programming/filtered?dateStart=$date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Programming.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        // Manejar el caso de token no válido
        authProvider.logout();
        throw Exception('Token no válido');
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return null;
      }

      final response = await http.get(
        Uri.parse('$API_URL/client-programming/$programmingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return Programming.fromJson(data);
      } else if (response.statusCode == 401) {
        authProvider.logout();
        throw Exception('Token no válido');
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
