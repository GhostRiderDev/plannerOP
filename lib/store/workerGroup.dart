import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';

class WorkerGroupsProvider with ChangeNotifier {
  // Lista de grupos
  final List<WorkerGroup> _groups = [];

  // Getter para acceder a la lista de grupos
  List<WorkerGroup> get groups => [..._groups];

  // Añadir un nuevo grupo
  void addGroup(WorkerGroup group) {
    _groups.add(group);
    notifyListeners();
  }

  // Eliminar un grupo
  void removeGroup(String groupId) {
    _groups.removeWhere((group) => group.id == groupId);
    notifyListeners();
  }

  // Recuperar un grupo por su ID
  WorkerGroup? getGroupById(String groupId) {
    return _groups.firstWhere((group) => group.id == groupId,
        orElse: () => WorkerGroup(workers: [], name: "", id: "", serviceId: 0));
  }

  // Remover un trabajador de su grupo
  void removeWorkerFromGroup(Worker worker) {
    for (var group in _groups) {
      final index = group.workers.indexWhere((wId) => wId == worker.id);
      if (index >= 0) {
        group.workers.removeAt(index);

        // Si el grupo queda vacío, eliminar el grupo
        if (group.workers.isEmpty) {
          _groups.remove(group);
        }

        notifyListeners();
        break;
      }
    }
  }

  // Obtener el grupo al que pertenece un trabajador
  WorkerGroup? getWorkerGroup(Worker worker) {
    for (var group in _groups) {
      if (group.workers.any((wId) => wId == worker.id)) {
        return group;
      }
    }
    return null;
  }

  // Verificar si un trabajador pertenece a algún grupo
  bool isWorkerInAnyGroup(Worker worker) {
    return _groups.any((group) => group.workers.any((wId) => wId == worker.id));
  }

  // Verificar si dos trabajadores están en el mismo grupo
  bool areWorkersInSameGroup(Worker worker1, Worker worker2) {
    for (var group in _groups) {
      if (group.workers.any((wId) => wId == worker1.id) &&
          group.workers.any((wId) => wId == worker2.id)) {
        return true;
      }
    }
    return false;
  }

  void clear() {
    _groups.clear();
    notifyListeners();
  }
}
