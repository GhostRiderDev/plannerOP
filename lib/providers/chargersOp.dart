import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/services/chargersOp/chargersOp.dart';
import 'package:plannerop/utils/toast.dart';

class ChargersOpProvider extends ChangeNotifier {
  final ChargersopService _chargersopService = ChargersopService();
  List<User> _chargers = [];

  List<User> get chargers => _chargers;

  void addCharger(User charger) {
    _chargers.add(charger);
    notifyListeners();
  }

  Future<void> fetchChargers(BuildContext context) async {
    try {
      final chargers = await _chargersopService.getChargers();
      _chargers = chargers;
      notifyListeners();
    } on SocketException catch (e) {
      showErrorToast(context, 'No Internet connection');
    } on HttpException catch (e) {
      showErrorToast(context, 'Failed to load chargers');
    } on FormatException catch (e) {
      showErrorToast(context, 'Bad response format');
    } catch (e) {
      showErrorToast(context, 'An unexpected error occurred');
      debugPrint('Error fetching chargers: $e');
    }
  }

  User getChargerById(int id) {
    return _chargers.firstWhere((charger) => charger.id == id,
        orElse: () =>
            User(id: 0, name: '', dni: "", phone: "", cargo: "", idSite: 0));
  }

  void clear() {
    _chargers = [];
    notifyListeners();
  }
}
