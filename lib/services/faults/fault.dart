import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/fault.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class FaultService {
  final String API_URL = dotenv.get('API_URL');

  // Método para obtener todas las faltas desde la API
  Future<List<Fault>> fetchFaults(BuildContext context) async {
    try {
      if (!context.mounted) {
        debugPrint('Context no está montado, abortando fetchFaults');
        return [];
      }

      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;
      final workersProvider =
          Provider.of<WorkersProvider>(context, listen: false);
      final workers = await workersProvider.workers;

      var url = Uri.parse('$API_URL/called-attention');
      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (!context.mounted) {
        debugPrint(
            'Context ya no está montado después de la llamada HTTP, abortando');
        return [];
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Fault> faults = [];

        for (var fault in jsonResponse) {
          try {
            if (workers.length == 0) {
              debugPrint('No hay trabajadores para asociar faltas');
              return [];
            }

            // Buscar el worker asociado a esta falta
            final workerId = fault['id_worker'] ?? fault['id_worker'];
            final worker = workers.firstWhere((w) => w.id == workerId,
                orElse: () => Worker(
                    name: "",
                    area: "",
                    phone: "",
                    document: "",
                    status: WorkerStatus.available,
                    startDate: DateTime.now(),
                    code: "",
                    id: 0));

            // Determinar el tipo de falta
            FaultType faultType;
            switch (fault['type']) {
              case 'INASSISTANCE':
                faultType = FaultType.INASSISTANCE;
                break;
              case 'IRRESPECTFUL':
                faultType = FaultType.IRRESPECTFUL;
                break;
              case 'ABANDONMENT':
                faultType = FaultType.ABANDONMENT;
                break;
              default:
                faultType = FaultType.INASSISTANCE;
            }

            faults.add(Fault(
              id: fault['id'],
              description: fault['description'] ?? 'Sin descripción',
              type: faultType,
              worker: worker,
              createdAt: DateTime.parse(fault['createAt']),
            ));
          } catch (e) {
            debugPrint('Error al procesar una falta: $e');
          }
        }

        return faults;
      } else {
        debugPrint(
            'Error al obtener faltas: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en fetchFaults: $e');
      return [];
    }
  }

  // Mantener el método original y añadir soporte para descripción
  Future<bool> registerFault(Worker worker, BuildContext context,
      {String? description}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }

      // Primero actualiza el contador de faltas en el worker
      var workerUrl = Uri.parse('$API_URL/worker/${worker.id}');
      var workerResponse = await http.patch(
        workerUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'failures': worker.failures + 1,
        }),
      );

      if (!(workerResponse.statusCode >= 200 &&
          workerResponse.statusCode < 300)) {
        return false;
      }

      // Si se proporcionó una descripción, registrar también la falta como incidente
      if (description != null && description.isNotEmpty) {
        var faultUrl = Uri.parse('$API_URL/called-attention');
        var faultResponse = await http.post(
          faultUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'description': description,
            'type': 'INASSISTANCE',
            'id_worker': worker.id,
          }),
        );

        if (!(faultResponse.statusCode >= 200 &&
            faultResponse.statusCode < 300)) {
          debugPrint(
              'La falta se registró pero hubo un error al guardar el incidente');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error en registerFault: $e');
      return false;
    }
  }

  // Nuevo método para registrar abandono de trabajo
  Future<bool> registerAbandonment(Worker worker, BuildContext context,
      {String? description}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }

      // Primero actualiza el contador de faltas en el worker
      var workerUrl = Uri.parse('$API_URL/worker/${worker.id}');
      var workerResponse = await http.patch(
        workerUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'failures': worker.failures + 1,
        }),
      );

      // debugPrint(
      //     'Worker API Response: ${workerResponse.statusCode} - ${workerResponse.body}');

      if (!(workerResponse.statusCode >= 200 &&
          workerResponse.statusCode < 300)) {
        return false;
      }

      if (description == null || description.isEmpty) {
        debugPrint('Se requiere una descripción para registrar abandono');
        return false;
      }

      var faultUrl = Uri.parse('$API_URL/called-attention');
      var response = await http.post(
        faultUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'description': description,
          'type': 'ABANDONMENT',
          'id_worker': worker.id,
        }),
      );

      // debugPrint(
      //     'Abandonment API Response: ${response.statusCode} - ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error en registerAbandonment: $e');
      return false;
    }
  }

  // Nuevo método para registrar falta de respeto
  Future<bool> registerDisrespect(Worker worker, BuildContext context,
      {String? description}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }

      // Primero actualiza el contador de faltas en el worker
      var workerUrl = Uri.parse('$API_URL/worker/${worker.id}');
      var workerResponse = await http.patch(
        workerUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'failures': worker.failures + 1,
        }),
      );

      // debugPrint(
      //     'Worker API Response: ${workerResponse.statusCode} - ${workerResponse.body}');

      if (!(workerResponse.statusCode >= 200 &&
          workerResponse.statusCode < 300)) {
        return false;
      }

      if (description == null || description.isEmpty) {
        debugPrint(
            'Se requiere una descripción para registrar falta de respeto');
        return false;
      }

      var faultUrl = Uri.parse('$API_URL/called-attention');
      var response = await http.post(
        faultUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'description': description,
          'type': 'IRRESPECTFUL',
          'id_worker': worker.id,
        }),
      );

      // debugPrint(
      //     'Disrespect API Response: ${response.statusCode} - ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error en registerDisrespect: $e');
      return false;
    }
  }
}
