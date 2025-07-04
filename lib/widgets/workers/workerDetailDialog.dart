import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';
import 'workerDetailsSection.dart';
import 'workerActionsBar.dart';
import 'workerEditDialog.dart';
import 'workerIncapacitationDialog.dart';
import 'workerRetirementDialog.dart';
import 'workerCodeBadge.dart';

class WorkerDetailDialog extends StatelessWidget {
  final Worker worker;
  final bool isAssigned;
  final Color specialtyColor;
  final Function(Worker, Worker) onUpdateWorker;
  final Function(Worker, DateTime, DateTime)? onIncapacitateWorker;
  final Function(Worker)? onRetireWorker;

  const WorkerDetailDialog({
    Key? key,
    required this.worker,
    required this.isAssigned,
    required this.specialtyColor,
    required this.onUpdateWorker,
    this.onIncapacitateWorker,
    this.onRetireWorker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera colorida
            _buildHeader(context, worker.code),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Detalles del trabajador
                  WorkerDetailsSection(
                    worker: worker,
                    specialtyColor: specialtyColor,
                    workerCode: worker.code,
                  ),
                ],
              ),
            ),

            // Barra de acciones
            WorkerActionsBar(
              worker: worker,
              specialtyColor: specialtyColor,
              onClose: () => Navigator.pop(context),
              onEdit: () => _showEditWorkerDialog(context),
              onIncapacitate: onIncapacitateWorker != null
                  ? () => _showIncapacitationDialog(context)
                  : null,
              onRetire: onRetireWorker != null
                  ? () => _showRetirementDialog(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String workerCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            specialtyColor,
            specialtyColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                worker.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: specialtyColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            worker.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),

          // Área del trabajador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              worker.area,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Código del trabajador
          WorkerCodeBadge(code: worker.code),

          const SizedBox(height: 8),

          // Estado del trabajador
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    String statusText;

    switch (worker.status) {
      case WorkerStatus.available:
        backgroundColor = Colors.green.withOpacity(0.2);
        statusText = 'Disponible';
        break;
      case WorkerStatus.assigned:
        backgroundColor = Colors.red.withOpacity(0.2);
        statusText = 'Asignado';
        break;
      case WorkerStatus.incapacitated:
        backgroundColor = Colors.purple.withOpacity(0.2);
        statusText = 'Incapacitado';
        break;
      case WorkerStatus.deactivated:
        backgroundColor = Colors.grey.withOpacity(0.2);
        statusText = 'Retirado';
        break;
      default:
        backgroundColor = Colors.blue.withOpacity(0.2);
        statusText = 'Estado Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Método que muestra el diálogo de edición
  void _showEditWorkerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WorkerEditDialog(
        worker: worker,
        specialtyColor: specialtyColor,
        onUpdateWorker: (oldWorker, newWorker) {
          // Actualizar el trabajador en el provider
          onUpdateWorker(oldWorker, newWorker);

          // También cerrar el diálogo de detalles para que se refresque
          Navigator.of(context).pop();

          // Opcional: Abrir nuevamente el diálogo con el trabajador actualizado
          // Solo si quieres que se reabra automáticamente
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              builder: (context) => WorkerDetailDialog(
                worker: newWorker,
                isAssigned: newWorker.status == WorkerStatus.assigned,
                specialtyColor: specialtyColor,
                onUpdateWorker: onUpdateWorker,
                onIncapacitateWorker: onIncapacitateWorker,
                onRetireWorker: onRetireWorker,
              ),
            );
          });
        },
      ),
    );
  }

// Ajustar los métodos de incapacitación y retiro
  void _showIncapacitationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WorkerIncapacitationDialog(
        worker: worker,
        onIncapacitate: (worker, startDate, endDate) {
          // Esta función se invoca desde dentro del diálogo WorkerIncapacitationDialog
          if (onIncapacitateWorker != null) {
            onIncapacitateWorker!(worker, startDate, endDate);
          }
        },
      ),
    ).then((_) {
      // Cerrar el diálogo de detalles después de procesar
      Navigator.of(context).pop();
    });
  }

  void _showRetirementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WorkerRetirementDialog(
        worker: worker,
        specialtyColor: specialtyColor,
        onRetire: (worker) {
          // Esta función se invoca desde dentro del diálogo WorkerRetirementDialog
          if (onRetireWorker != null) {
            onRetireWorker!(worker);
          }
        },
      ),
    ).then((_) {
      // Cerrar el diálogo de detalles después de procesar
      Navigator.of(context).pop();
    });
  }
}
