import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/network/httpClient.dart';

class AreaService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Area>> fetchAreas() async {
    var url = '/area';

    var response = await _apiClient.get(url);

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
