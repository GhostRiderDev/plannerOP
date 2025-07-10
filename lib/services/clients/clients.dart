import 'dart:convert';

import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/network/httpClient.dart';
import 'package:plannerop/dto/clients/fetchClients.dart';

class ClientService {
  final ApiClient _apiClient = ApiClient();

  Future<FetchclientsDto> fetchClients() async {
    var url = '/client';

    var response = await _apiClient.get(url);
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
