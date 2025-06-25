import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/store/auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class SiteService {
  final String API_URL = dotenv.get('API_URL');

  // Método para obtener todos los sitios
  Future<List<dynamic>> getAllSites(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return [];
      }

      final response = await http.get(
        Uri.parse('$API_URL/site'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

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
