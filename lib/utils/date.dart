// Formatear fecha en formato YYYY-MM-DD
String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

DateTime combineDateAndTime(String dateStr, String timeStr) {
  final date = DateTime.parse(dateStr);
  final timeParts = timeStr.split(':');
  final hours = int.parse(timeParts[0]);
  final minutes = int.parse(timeParts[1]);

  return DateTime(date.year, date.month, date.day, hours, minutes);
}
