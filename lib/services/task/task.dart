import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/dto/taks/fetchTask.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:provider/provider.dart';

class TaskService {
  final String API_URL = dotenv.get('API_URL');

  // Método para obtener tareas con token directo
  Future<FetchTasksDto> fetchTasksWithToken(String token) async {
    try {
      var url = Uri.parse('$API_URL/task');
      var response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final List<Task> tasks = [];
        for (var t in jsonResponse) {
          try {
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
        debugPrint('Error en API: ${response.statusCode} - ${response.body}');
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

  // Método que utiliza el contexto para obtener el token
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

      return await fetchTasksWithToken(token);
    } catch (e) {
      debugPrint('Error en contexto de fetchTasks: $e');
      return FetchTasksDto(
        tasks: [],
        isSuccess: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  // Método para crear una tarea
  Future<bool> createTask(BuildContext context, Task task) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;
      final profileProvider = Provider.of<UserProvider>(context, listen: false);

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }

      var url = Uri.parse('$API_URL/task');
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(task.toJson(profileProvider.user.id)),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Error en API: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error en createTask: $e');
      return false;
    }
  }
}
