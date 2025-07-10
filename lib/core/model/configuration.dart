class Configuration {
  final int id;
  final String name;
  final String description;
  final ConfigurationType typeValue;
  final String value;
  final ConfigurationStatus status;

  Configuration({
    required this.id,
    required this.name,
    required this.description,
    required this.typeValue,
    required this.value,
    required this.status,
  });
}

enum ConfigurationStatus {
  active,
  inactive,
}

enum ConfigurationType { int, decimal, string, boolean, date }
