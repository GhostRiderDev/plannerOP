import 'package:flutter/material.dart';
import 'package:plannerop/core/model/site.dart';
import 'package:plannerop/core/model/user.dart';

class UserProvider with ChangeNotifier {
  late User _user;
  bool _hasUser = false;

  User get user => _user;
  bool get hasUser => _hasUser;

  Site? _selectedSite;
  Site? _selectedSubsite;
  List<Site> _availableSites = [];

  Site? get selectedSite => _selectedSite;
  Site? get selectedSubsite => _selectedSubsite;
  List<Site> get availableSites => _availableSites;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Método para limpiar los datos del usuario
  void clearUser() {
    _hasUser = false;
    notifyListeners();
  }

  void setSelectedSite(Site? site) {
    _selectedSite = site;
    notifyListeners();
  }

  void setSelectedSubsite(Site? subsite) {
    _selectedSubsite = subsite;
    notifyListeners();
  }

  void setAvailableSites(List<Site> sites) {
    _availableSites = sites;
    notifyListeners();
  }

  void clear() {
    _hasUser = false;
    _selectedSite = null;
    _availableSites = [];
    notifyListeners();
  }
}
