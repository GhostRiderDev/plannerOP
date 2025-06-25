import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:plannerop/core/model/area.dart';

class AreaService {
  final String API_URL = dotenv.get('API_URL');
  Future<List<Area>> fetchAreas(String token) async {
    var url = Uri.parse(API_URL + '/area');

    var response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // debugPrint(jsonResponse.toString());
      List<Area> areas = [];
      for (var area in jsonResponse) {
        if (area['status'] != 'ACTIVE') continue; // Filtrar áreas inactivas
        areas.add(Area(id: area['id'], name: area['name']));
      }

      return areas;
    } else {
      debugPrint('Error al obtener las áreas');
      return [];
    }
  }
}
