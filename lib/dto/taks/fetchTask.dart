import 'package:plannerop/core/model/task.dart';

class FetchTasksDto {
  final List<Task> tasks;
  final bool isSuccess;
  final String? errorMessage;

  FetchTasksDto({
    required this.tasks,
    required this.isSuccess,
    this.errorMessage,
  });
}
