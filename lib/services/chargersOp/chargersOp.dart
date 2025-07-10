import 'dart:convert';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/network/httpClient.dart';

class ChargersopService {
  final ApiClient _apiClient = ApiClient();

  Future<List<User>> getChargers() async {
    try {
      final response = await _apiClient.get('/user');

      if (response.statusCode == 200) {
        final List<dynamic> chargers = jsonDecode(response.body);
        return chargers
            .where((charger) =>
                charger['occupation'] == 'SUPERVISOR' ||
                charger['occupation'] == 'COORDINADOR')
            .where((charger) => charger['status'] == 'ACTIVE')
            .map((charger) => User.fromJson(charger))
            .toList();
      } else {
        throw Exception('Failed to load chargers');
      }
    } catch (e) {
      throw e;
    }
  }
}
