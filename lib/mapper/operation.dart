import 'package:flutter/material.dart';

// Función para obtener el texto del estado en español
String getOperationStatusText(String status) {
  switch (status.toUpperCase()) {
    case 'UNASSIGNED':
      return 'Sin Asignar';
    case 'ASSIGNED':
      return 'Asignada';
    case 'COMPLETED':
      return 'Completada';
    case 'CANCELLED':
      return 'Cancelada';
    default:
      return status;
  }
}

Color getStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return Colors.orange;
    case 'INPROGRESS':
      return Colors.blue;
    case 'COMPLETED':
      return Colors.green;
    case 'CANCELLED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Helper para obtener el ícono según el estado
IconData getStatusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return Icons.pending_outlined;
    case 'INPROGRESS':
      return Icons.sync;
    case 'COMPLETED':
      return Icons.check_circle_outline;
    case 'CANCELED':
      return Icons.cancel_outlined;
    default:
      return Icons.pending_outlined;
  }
}
