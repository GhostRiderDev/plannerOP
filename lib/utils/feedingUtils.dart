import 'package:flutter/material.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:provider/provider.dart';

class FeedingUtils {
  /// Helper para convertir string de hora a TimeOfDay
  static TimeOfDay? _parseTimeString(String timeString) {
    try {
      final List<String> parts = timeString.split(':');
      if (parts.length < 2) return null;
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      debugPrint('Error al parsear hora: $e');
      return null;
    }
  }

  // NUEVO: Método para determinar comidas considerando el estado de entrega
  static List<String> determinateFoodsWithDeliveryStatus(
      String? horaInicio, String? horaFin, BuildContext context,
      {int? operationId, int? workerId}) {
    final feedingProvider =
        Provider.of<FeedingProvider>(context, listen: false);

    // Primero obtener las comidas normalmente
    List<String> foods = determinateFoods(horaInicio, horaFin, context);

    // Si no hay operationId o workerId, retornar como siempre
    if (operationId == null || workerId == null) {
      return foods;
    }

    // Si hay una comida válida, verificar si ya fue entregada
    if (foods.isNotEmpty &&
        foods[0] != "Sin alimentación" &&
        foods[0] != "Sin alimentación actual") {
      String foodType = foods[0];
      bool yaEntregada =
          feedingProvider.isMarked(operationId, workerId, foodType);

      if (yaEntregada) {
        return ["$foodType ya entregado"];
      }
    }

    return foods;
  }

  static List<String> determinateFoods(
      String? horaInicio, String? horaFin, BuildContext context) {
    List<String> foods = [];

    // 1. Obtener la hora actual
    DateTime now = DateTime.now();
    TimeOfDay currentTime =
        TimeOfDay(hour: 7, minute: 20); // Cambiar a 8:00 AM para testing
    int currentMinutes = currentTime.hour * 60 + currentTime.minute;

    // 2. Convertir strings de hora a objetos TimeOfDay para la operación
    TimeOfDay? inicio =
        horaInicio != null ? _parseTimeString(horaInicio) : null;
    TimeOfDay? fin = horaFin != null ? _parseTimeString(horaFin) : null;

    if (inicio == null)
      return ["Sin alimentación"]; // Sin hora de inicio, no hay comidas

    // Convertir horas a minutos para facilitar comparaciones
    int inicioMinutos = inicio.hour * 60 + inicio.minute;
    int finMinutos = fin != null
        ? fin.hour * 60 + fin.minute
        : inicioMinutos + 1440; // Asumir 24 horas de duración por defecto

    // Si la operación termina antes que inicia, asumimos que cruza la medianoche
    if (finMinutos < inicioMinutos) {
      finMinutos += 24 * 60; // Sumar un día completo
    }

    // 3. Definir horarios exactos de comidas
    int desayunoHora = 6 * 60; // 6:00 am
    int almuerzoHora = 12 * 60; // 12:00 pm
    int cenaHora = 18 * 60; // 6:00 pm
    int mediaNocheHora = 0; // 00:00 am

    // 4. Definir periodos extendidos para cada comida (cuando se puede reclamar)
    int periodoDesayuno = 10 * 60; // Hasta las 10 am
    int periodoAlmuerzo = 16 * 60; // Hasta las 4 pm
    int periodoCena = 21 * 60; // Hasta las 9 pm
    int periodoMediaNoche = 3 * 60; // Hasta las 3 am

    // Verificar si la operación está activa actualmente
    bool operacionEnCursoAhora = (inicioMinutos <= currentMinutes) &&
        (finMinutos >= currentMinutes || fin == null);

    if (!operacionEnCursoAhora) {
      return [
        "Sin alimentación"
      ]; // Si la operación no está en curso, no hay alimentación
    }

    // NUEVA LÓGICA: Una operación tiene derecho a una comida solo si:
    // 1. La operación comienza ANTES de la hora de esa comida, Y
    // 2. La operación termina DESPUÉS de la hora de esa comida
    List<String> comidasAutorizadas = [];

    // Desayuno - 6:00 am
    if (inicioMinutos < desayunoHora && finMinutos > desayunoHora) {
      comidasAutorizadas.add('Desayuno');
    }

    // Almuerzo - 12:00 pm
    if (inicioMinutos < almuerzoHora && finMinutos > almuerzoHora) {
      comidasAutorizadas.add('Almuerzo');
    }

    // Cena - 6:00 pm
    if (inicioMinutos < cenaHora && finMinutos > cenaHora) {
      comidasAutorizadas.add('Cena');
    }

    // Media noche - 00:00 am (caso especial por cruce de día)
    if (inicioMinutos < mediaNocheHora && finMinutos > mediaNocheHora) {
      comidasAutorizadas.add('Media noche');
    }
    // Caso especial: operación que inicia antes de medianoche y termina después
    else if (inicioMinutos < (24 * 60) && finMinutos > (24 * 60)) {
      comidasAutorizadas.add('Media noche');
    }

    if (comidasAutorizadas.isEmpty) {
      return ["Sin alimentación"];
    }

    // Determinar cuál comida mostrar según la hora actual
    // Solo mostrar la comida que corresponde al periodo actual
    String comidaActual = '';

    // Entre 12 am y 3 am: Media noche
    if (currentMinutes >= mediaNocheHora &&
        currentMinutes <= periodoMediaNoche) {
      if (comidasAutorizadas.contains('Media noche')) {
        comidaActual = 'Media noche';
      }
    }
    // Entre 6 am y 10 am: Desayuno
    else if (currentMinutes >= desayunoHora &&
        currentMinutes <= periodoDesayuno) {
      if (comidasAutorizadas.contains('Desayuno')) {
        comidaActual = 'Desayuno';
      }
    }
    // Entre 12 pm y 4 pm: Almuerzo
    else if (currentMinutes >= almuerzoHora &&
        currentMinutes <= periodoAlmuerzo) {
      if (comidasAutorizadas.contains('Almuerzo')) {
        comidaActual = 'Almuerzo';
      }
    }
    // Entre 6 pm y 9 pm: Cena
    else if (currentMinutes >= cenaHora && currentMinutes <= periodoCena) {
      if (comidasAutorizadas.contains('Cena')) {
        comidaActual = 'Cena';
      }
    }
    // Entre 9 pm y 12 am: Media noche (si la operación va a cruzar medianoche)
    else if (currentMinutes >= periodoCena && currentMinutes < 24 * 60) {
      if (comidasAutorizadas.contains('Media noche')) {
        comidaActual = 'Media noche';
      }
    }

    // Si tenemos una comida válida para el período actual, la retornamos
    if (comidaActual.isNotEmpty) {
      foods.add(comidaActual);
      return foods;
    }

    // Si no hay comida para el período actual pero hay comidas autorizadas,
    // retornar un caso especial para indicar que hay alimentación pero fuera de horario
    return ["Sin alimentación actual"];
  }

  /// Determina si una operación tiene derecho a comida específica en este momento
  static bool tieneDerechoAComidaAhora(
      String? horaInicio, String? horaFin, BuildContext context) {
    List<String> comidas = determinateFoods(horaInicio, horaFin, context);
    return comidas.isNotEmpty &&
        comidas[0] != "Sin alimentación" &&
        comidas[0] != "Sin alimentación actual";
  }

  /// Verificar si la alimentación actual puede ser marcada (no está ya entregada)
  static bool puedeMarcarAlimentacion(String? horaInicio, String? horaFin,
      BuildContext context, int operationId, int workerId) {
    List<String> foods = determinateFoodsWithDeliveryStatus(
        horaInicio, horaFin, context,
        operationId: operationId, workerId: workerId);

    return foods.isNotEmpty &&
        !foods[0].contains("Sin alimentación") &&
        !foods[0].contains("ya entregado");
  }
}
