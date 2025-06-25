class StatusMapper {
  /// Mapear de estado UI a estado de la API
  static String mapUIStatusToAPI(String uiStatus) {
    switch (uiStatus) {
      case 'Completada':
        return 'COMPLETED';
      case 'En curso':
        return 'INPROGRESS';
      case 'Pendiente':
        return 'PENDING';
      case 'Cancelada':
        return 'CANCELED';
      default:
        return uiStatus.toUpperCase();
    }
  }

  /// Mapear de estado de la API a estado UI
  static String mapAPIStatusToUI(String apiStatus) {
    switch (apiStatus.toUpperCase()) {
      case 'COMPLETED':
        return 'Completada';
      case 'INPROGRESS':
        return 'En curso';
      case 'PENDING':
        return 'Pendiente';
      case 'CANCELED':
        return 'Cancelada';
      default:
        return apiStatus;
    }
  }
}
