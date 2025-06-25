import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerListItem extends StatelessWidget {
  final Worker worker;
  final Color specialtyColor;
  final VoidCallback onTap;

  const WorkerListItem({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.onTap,
  }) : super(key: key);

  // Determina si se debe marcar el trabajador como crítico
  bool get _isCriticalWorker => worker.failures >= 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: _isCriticalWorker
            ? Border.all(color: const Color(0xFFF56565), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: _isCriticalWorker
                ? const Color(0xFFF56565).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: _isCriticalWorker ? 10 : 8,
            spreadRadius: _isCriticalWorker ? 1 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Stack(
            children: [
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Círculo con la inicial
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isCriticalWorker
                            ? const Color(0xFFFED7D7)
                            : specialtyColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          worker.name.isNotEmpty
                              ? worker.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _isCriticalWorker
                                ? const Color(0xFFC53030)
                                : specialtyColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Información del trabajador
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  worker.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                              if (_isCriticalWorker)
                                Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: _buildFailuresBadge(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: specialtyColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                worker.area,
                                style: const TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Estado (asignado/disponible)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: worker.status == WorkerStatus.assigned
                            ? const Color(0xFFFED7D7)
                            : worker.status == WorkerStatus.available
                                ? const Color(0xFFC6F6D5)
                                : worker.status == WorkerStatus.incapacitated
                                    ? Colors.purple[200]
                                    : worker.status == WorkerStatus.deactivated
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        worker.status == WorkerStatus.assigned
                            ? 'Asignado'
                            : worker.status == WorkerStatus.available
                                ? 'Disponible'
                                : worker.status == WorkerStatus.incapacitated
                                    ? 'Incapacitado'
                                    : worker.status == WorkerStatus.deactivated
                                        ? 'Retirado'
                                        : 'Desconocido',
                        style: TextStyle(
                          color: worker.status == WorkerStatus.assigned
                              ? const Color(0xFFC53030)
                              : worker.status == WorkerStatus.available
                                  ? const Color(0xFF2F855A)
                                  : worker.status == WorkerStatus.incapacitated
                                      ? Colors.purple[800]
                                      : worker.status ==
                                              WorkerStatus.deactivated
                                          ? const Color(0xFF718096)
                                          : const Color(0xFF718096),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador visual de faltas críticas
              if (_isCriticalWorker)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF56565),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar el contador de faltas
  Widget _buildFailuresBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF56565),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            '${worker.failures}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
