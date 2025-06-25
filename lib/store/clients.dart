import 'package:flutter/material.dart';
import 'package:plannerop/services/clients/clients.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/store/auth.dart';
import 'package:provider/provider.dart';

class ClientsProvider with ChangeNotifier {
  List<Client> _clients = [];
  ClientService _clientService = ClientService();

  List<Client> get clients {
    return [..._clients];
  }

  void addClient(Client client) {
    _clients.add(client);
    notifyListeners();
  }

  Future<void> fetchClients(BuildContext context) async {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    var token = authProvider.accessToken;

    try {
      var fetchClientsDto = await _clientService.fetchClients(token);
      if (fetchClientsDto.isSuccess) {
        _clients = fetchClientsDto.clients;
        notifyListeners();
      } else {
        debugPrint('Error al obtener clientes');
      }
    } catch (e) {
      debugPrint('Error al obtener clientes: $e');
    }
  }

  Client getClientById(int id) {
    return _clients.firstWhere((client) => client.id == id,
        orElse: () => Client(id: 0, name: ''));
  }

  Client getClientByName(String name) {
    return _clients.firstWhere((client) => client.name == name,
        orElse: () => Client(id: 0, name: ''));
  }

  void clear() {
    _clients = [];
    notifyListeners();
  }
}
