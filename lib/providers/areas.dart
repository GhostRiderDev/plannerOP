import 'package:flutter/material.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/providers/auth.dart';
import 'package:plannerop/services/areas/areas.dart';
import 'package:provider/provider.dart';

class AreasProvider extends ChangeNotifier {
  List<Area> _areas = [];
  final AreaService _areaService = AreaService();

  List<Area> get areas => _areas;

  void setAreas(List<Area> areas) {
    _areas = areas;
    notifyListeners();
  }

  Future<void> fetchAreas() async {
    if (_areas.isEmpty) {
      try {
        final List<Area> areas = await _areaService.fetchAreas();
        setAreas(areas);
      } catch (e) {
        debugPrint('Error al obtener las áreas en FetchAreas_provider');
      }
    }
  }

  Area? getAreaById(int id) {
    return _areas.firstWhere((area) => area.id == id,
        orElse: () => Area(
              id: 0,
              name: 'No encontrado',
            ));
  }

  Area getAreaByName(String name) {
    return _areas.firstWhere((area) => area.name == name,
        orElse: () => Area(id: 0, name: ""));
  }

  void clear() {
    _areas = [];
    notifyListeners();
  }
}
