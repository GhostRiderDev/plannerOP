import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/store/auth.dart';
import 'package:provider/provider.dart';

class ChargersopService {
  final String API_URL = dotenv.get('API_URL');

  Future<List<User>> getChargers(BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      final response = await http.get(
        Uri.parse('$API_URL/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> chargers = jsonDecode(response.body);
        for (var charger in chargers) {
          print('charger: $charger');
        }
        return chargers
            .where((charger) =>
                charger['occupation'] == 'SUPERVISOR' ||
                charger['occupation'] == 'COORDINADOR')
            .map((charger) => User.fromJson(charger))
            .toList();
      } else {
        throw Exception('Failed to load chargers');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to load chargers');
    }
  }
}
