import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:plannerop/core/model/configuration.dart';
import 'package:plannerop/core/network/httpClient.dart';

class ConfigurationService {
  final ApiClient _apiClient = ApiClient();

  // Método para obtener todas las configuraciones desde la API
  Future<List<Configuration>> fetchConfigurations() async {
    try {
      var response = await _apiClient.get("/configurations");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Configuration> configurations = [];

        for (var fault in jsonResponse) {
          try {
            configurations.add(Configuration(
              id: fault['id'] ?? 0,
              name: fault['name'] ?? '',
              description: fault['description'] ?? '',
              typeValue: ConfigurationType.values.firstWhere(
                (e) => e.toString() == '${fault['type']}',
                orElse: () => ConfigurationType.string,
              ),
              value: fault['value'] ?? '',
              status: ConfigurationStatus.values.firstWhere(
                (e) => e.toString() == '${fault['status']}',
                orElse: () => ConfigurationStatus.active,
              ),
            ));
          } catch (e) {
            debugPrint('Error al procesar una configuracion: $e');
          }
        }

        return configurations;
      } else {
        debugPrint(
            'Error al obtener configuraciones: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en fetchConfiguraciones: $e');
      return [];
    }
  }
}
