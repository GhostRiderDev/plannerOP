import 'package:plannerop/core/model/subtask.dart';

class Task {
  final String name;
  final int id;
  List<SubTask> subtasks;

  Task({required this.name, required this.id, required this.subtasks});

  @override
  String toString() => name;

  // Factory constructor para crear desde JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      subtasks: (json['SubTask'] as List)
          .map((subtask) => SubTask.fromJson(subtask))
          .toList(),
      name: json['name'].toString().toUpperCase(),
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson(int id) {
    return {
      'id': id,
      'name': name,
      'SubTask': subtasks.map((subtask) => subtask.toJson(id)).toList(),
    };
  }
}
