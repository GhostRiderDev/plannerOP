import 'package:flutter/material.dart';
import 'package:plannerop/core/model/configuration.dart';
import 'package:plannerop/services/configuration/configuration.dart';

class ConfigurationProvider extends ChangeNotifier {
  final ConfigurationService _configurationService = ConfigurationService();

  Future<List<Configuration>> fetchConfigurations(BuildContext) {
    return _configurationService.fetchConfigurations();
  }
}
