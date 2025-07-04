import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/dto/clients/fetchClients.dart';

class ClientService {
  final String API_URL = dotenv.get('API_URL');

  Future<FetchclientsDto> fetchClients(String token) async {
    var url = Uri.parse(API_URL + '/client');

    var response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<Client> clients = [];
      for (var client in jsonResponse) {
        if (client['status'] != 'ACTIVE')
          continue; // Filtrar clientes inactivos
        clients.add(Client(id: client['id'], name: client['name']));
      }
      return FetchclientsDto(clients: clients, isSuccess: true);
    } else {
      return FetchclientsDto(clients: [], isSuccess: false);
    }
  }
}
