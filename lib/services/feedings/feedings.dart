import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plannerop/core/network/httpClient.dart';

class FeedingService {
  final ApiClient _apiClient = ApiClient();

  // MODIFICAR markFeeding para devolver el ID
  Future<Map<String, dynamic>> markFeeding({
    required int workerId,
    required int operationId,
    required String type,
  }) async {
    try {
      String currentDateTime = DateTime.now()
          .toIso8601String()
          .substring(0, 16)
          .replaceAll('T', ' ');

      final payload = {
        'id_worker': workerId,
        'id_operation': operationId,
        'dateFeeding': currentDateTime,
        'type': type,
      };

      final response = await _apiClient.post(
        '/feeding',
        body: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        //  PARSEAR RESPUESTA PARA OBTENER EL ID
        final responseData = jsonDecode(response.body);
        final int feedingId = responseData['id'] ?? responseData['feeding_id'];

        return {
          'success': true,
          'id': feedingId,
        };
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false};
    }
  }

  //  MÉTODO para desmarcar por ID específico
  Future<bool> unmarkFeedingById({
    required int feedingId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/feeding/$feedingId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  //  ASEGURAR que getFeedingsForOperation incluya los IDs
  Future<List<dynamic>> getFeedingsForOperation(int operationId) async {
    try {
      final response = await _apiClient.get(
        '/feeding/operation/$operationId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> feedingData = jsonDecode(response.body);

        //  VERIFICAR QUE CADA REGISTRO TENGA ID
        for (var feeding in feedingData) {
          if (!feeding.containsKey('id')) {
            debugPrint('⚠️ Registro de alimentación sin ID: $feeding');
          }
        }

        return feedingData;
      } else {
        debugPrint('Error al obtener alimentaciones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de conexión al obtener alimentaciones: $e');
      return [];
    }
  }
}
