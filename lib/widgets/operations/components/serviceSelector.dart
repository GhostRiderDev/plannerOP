import 'package:flutter/material.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/widgets/operations/components/utils/Button.dart';

/// Versión mejorada del selector de servicios para grupos (selección única)
Widget buildServiceSelector(
  BuildContext context,
  List<Task> availableTasks,
  int selectedServiceId,
  Function(int) onServicesChanged,
) {
  // Obtener la tarea seleccionada (si hay alguna)
  final Task? selectedTask = availableTasks.firstWhere(
    (task) => task.id == selectedServiceId,
    orElse: () => Task(id: -1, name: ''),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Encabezado
      const Text(
        'Servicio para este grupo',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),

      // Contenedor principal con vista previa
      GestureDetector(
        onTap: () {
          _showSingleServiceSelector(context, availableTasks, selectedServiceId,
              (newSelectedId) {
            // Convertir el ID único a una lista con un solo elemento
            onServicesChanged(newSelectedId != null ? newSelectedId : 0);
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Contenido principal
              Expanded(
                child: selectedTask == null
                    ? const Text(
                        'Toca para seleccionar servicio',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTask.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Servicio seleccionado para el grupo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
              ),

              // Icono de acción
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),

      // Mensaje de validación si es necesario
      if (selectedServiceId == null)
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child: Text(
            'Selecciona un servicio',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}

// Modal a pantalla completa para seleccionar un único servicio
void _showSingleServiceSelector(
  BuildContext context,
  List<Task> availableTasks,
  int? initialSelection,
  Function(int?) onServiceSelected,
) {
  // Variable local para la selección actual
  int? workingSelection = initialSelection;
  String searchQuery = '';
  List<Task> filteredTasks = List.from(availableTasks);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          // Función para filtrar tareas
          void filterTasks(String query) {
            setModalState(() {
              searchQuery = query.toLowerCase();
              if (searchQuery.isEmpty) {
                filteredTasks = List.from(availableTasks);
              } else {
                filteredTasks = availableTasks
                    .where(
                        (task) => task.name.toLowerCase().contains(searchQuery))
                    .toList();
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Barra superior con título y acciones
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Seleccionar servicio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (workingSelection != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              workingSelection = null;
                            });
                          },
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),

                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar servicio...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                filterTasks('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: filterTasks,
                  ),
                ),

                // Lista de servicios
                Expanded(
                  child: filteredTasks.isEmpty
                      ? _buildEmptyServicesList(searchQuery)
                      : ListView.builder(
                          itemCount: filteredTasks.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final isSelected = workingSelection == task.id;

                            return ListTile(
                              dense: true,
                              title: Text(
                                task.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.blue.shade800
                                      : Colors.black87,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.radio_button_checked,
                                      color: Colors.blue.shade700,
                                    )
                                  : Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.grey.shade400,
                                    ),
                              onTap: () {
                                setModalState(() {
                                  // Para selección única, solo asignamos o quitamos el valor
                                  workingSelection =
                                      isSelected ? null : task.id;
                                });
                              },
                            );
                          },
                        ),
                ),

                // // Footer con botón de guardar
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.05),
                //         blurRadius: 4,
                //         offset: const Offset(0, -1),
                //       ),
                //     ],
                //   ),
                //   child: SafeArea(
                //     child: SizedBox(
                //       width: double.infinity,
                //       child: ElevatedButton(
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: const Color(0xFF3182CE),
                //           padding: const EdgeInsets.symmetric(vertical: 16),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(8),
                //           ),
                //           disabledBackgroundColor: Colors.grey.shade300,
                //         ),
                //         onPressed: workingSelection != null
                //             ? () {
                //                 onServiceSelected(workingSelection);
                //                 Navigator.pop(context);
                //               }
                //             : null,
                //         child: Text(
                //           workingSelection != null
                //               ? 'Confirmar selección'
                //               : 'Selecciona un servicio',
                //           style: TextStyle(
                //             fontSize: 16,
                //             fontWeight: FontWeight.bold,
                //             color: workingSelection != null
                //                 ? Colors.white
                //                 : Colors.grey.shade500,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),

                AppButton(
                  text: workingSelection != null
                      ? 'Confirmar selección'
                      : 'Selecciona un servicio',
                  onPressed: workingSelection != null
                      ? () {
                          onServiceSelected(workingSelection);
                          Navigator.pop(context);
                        }
                      : null,
                  isFullWidth: true,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// Widget para mostrar cuando no hay servicios disponibles o coincidentes
Widget _buildEmptyServicesList(String searchQuery) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isEmpty ? Icons.work_off : Icons.search_off,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No hay servicios disponibles'
                : 'No se encontraron servicios para "$searchQuery"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Contacta con un administrador para añadir servicios'
                : 'Intenta con otro término de búsqueda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ),
  );
}
