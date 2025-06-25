import 'package:plannerop/core/model/client.dart';

class FetchclientsDto {
  final List<Client> clients;
  final bool isSuccess;

  FetchclientsDto({
    required this.clients,
    required this.isSuccess,
  });
}
