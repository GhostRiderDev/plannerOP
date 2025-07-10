import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/network/httpClient.dart';
import 'package:plannerop/dto/taks/fetchTask.dart';
import 'package:plannerop/providers/auth.dart';
import 'package:provider/provider.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

  // Método para obtener tareas con token directo
  Future<FetchTasksDto> fetchTasks(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return FetchTasksDto(
          tasks: [],
          isSuccess: false,
          errorMessage: 'No hay token disponible',
        );
      }

      var response = await _apiClient.get('/task');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final List<Task> tasks = [];
        for (var t in jsonResponse) {
          try {
            if (t['status'] != 'ACTIVE') continue; // Filtrar tareas inactivas
            tasks.add(Task.fromJson(t));
          } catch (e) {
            debugPrint('Error procesando tarea: $e');
          }
        }

        return FetchTasksDto(
          tasks: tasks,
          isSuccess: true,
        );
      } else {
        return FetchTasksDto(
          tasks: [],
          isSuccess: false,
          errorMessage: 'Error al obtener tareas: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error en fetchTasks: $e');
      return FetchTasksDto(
        tasks: [],
        isSuccess: false,
        errorMessage: 'Error: $e',
      );
    }
  }
}
