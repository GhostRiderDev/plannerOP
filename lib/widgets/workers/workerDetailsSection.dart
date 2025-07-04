import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/incapacity.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/incapacities.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/utils/toast.dart';

// Cambiamos de StatelessWidget a StatefulWidget para poder manejar estado local
class WorkerDetailsSection extends StatefulWidget {
  final Worker worker;
  final Color specialtyColor;
  final String workerCode;

  const WorkerDetailsSection({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.workerCode,
  }) : super(key: key);

  @override
  State<WorkerDetailsSection> createState() => _WorkerDetailsSectionState();
}

class _WorkerDetailsSectionState extends State<WorkerDetailsSection> {
  // Variable local para mantener el número actual de faltas

  // Variables para la información de incapacidad
  late int currentFailures;
  Incapacity? currentIncapacity;
  bool isLoadingIncapacity = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con el valor del worker
    currentFailures = widget.worker.failures;

    // Cargar información de incapacidad si el trabajador está incapacitado
    if (widget.worker.status == WorkerStatus.incapacitated) {
      _loadCurrentIncapacity();
    }
  }

  @override
  void didUpdateWidget(WorkerDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar si el worker cambió
    if (widget.worker.failures != currentFailures) {
      currentFailures = widget.worker.failures;
    }

    // Recargar incapacidad si el estado cambió
    if (oldWidget.worker.status != widget.worker.status &&
        widget.worker.status == WorkerStatus.incapacitated) {
      _loadCurrentIncapacity();
    }
  }

  // Método para cargar la incapacidad actual
  Future<void> _loadCurrentIncapacity() async {
    if (widget.worker.incapacityStartDate == null ||
        widget.worker.incapacityEndDate == null) {
      return;
    }

    setState(() {
      isLoadingIncapacity = true;
    });

    try {
      final incapacityProvider =
          Provider.of<IncapacityProvider>(context, listen: false);
      final incapacity = await incapacityProvider.getCurrentIncapacityForWorker(
        widget.worker.id,
        widget.worker.incapacityStartDate,
        widget.worker.incapacityEndDate,
        context,
      );

      if (mounted) {
        setState(() {
          currentIncapacity = incapacity;
          isLoadingIncapacity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingIncapacity = false;
        });
      }
      debugPrint('Error cargando incapacidad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de contacto
        _buildInfoSection(
          title: 'Información Personal',
          icon: Icons.person_outline,
          color: widget.specialtyColor,
          content: [
            _buildInfoRow(
                Icons.badge_outlined, 'Documento', widget.worker.document),
            _buildInfoRow(
                Icons.phone_outlined, 'Teléfono', widget.worker.phone),
            _buildInfoRow(Icons.calendar_today_outlined, 'Fecha de inicio',
                DateFormat('dd/MM/yyyy').format(widget.worker.startDate)),
            _buildInfoRow(Icons.qr_code_outlined, 'Código', widget.workerCode),
          ],
        ),

        const SizedBox(height: 20),

        // Información de estado
        _buildStatusSection(),

        const SizedBox(height: 20),

        // Sección de faltas
        _buildFaultsSection(context),
      ],
    );
  }

  // Sección de faltas mejorada
  Widget _buildFaultsSection(BuildContext context) {
    // Si el trabajador está retirado, no mostrar esta sección
    if (widget.worker.status == WorkerStatus.deactivated) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.amber[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Registro de Incidencias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contador de faltas con visualización
              _buildFaultCounter(),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Registrar nueva incidencia:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Distribución vertical de tarjetas en lugar de forzar dos por fila
              _buildIncidentCard(
                title: 'Falta',
                icon: Icons.event_busy_outlined,
                color: const Color(0xFFED8936),
                description: 'No asistencia al trabajo',
                onTap: () => _showAddFaultDialog(context, 'falta'),
                fullWidth: true,
              ),
              const SizedBox(height: 8),

              _buildIncidentCard(
                title: 'Abandono de Trabajo',
                icon: Icons.exit_to_app,
                color: const Color(0xFFE53E3E),
                description: 'Salida sin autorización previa',
                onTap: () => _showAddFaultDialog(context, 'abandono'),
                fullWidth: true,
              ),
              const SizedBox(height: 8),

              _buildIncidentCard(
                title: 'Falta de Respeto',
                icon: Icons.sentiment_very_dissatisfied_outlined,
                color: const Color(0xFF805AD5),
                description: 'Comportamiento inapropiado o irrespetuoso',
                onTap: () => _showAddFaultDialog(context, 'falta_respeto'),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tarjeta para cada tipo de incidencia - actualizada
  Widget _buildIncidentCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  // Tarjeta para cada tipo de incidencia

// Diálogo mejorado para registrar cualquier tipo de incidencia
  Future<void> _showAddFaultDialog(
      BuildContext context, String incidentType) async {
    String dialogTitle;
    Color accentColor;
    IconData headerIcon;

    // Configurar diálogo según el tipo de incidencia
    switch (incidentType) {
      case 'abandono':
        dialogTitle = 'Registrar Abandono';
        accentColor = Colors.red;
        headerIcon = Icons.exit_to_app;
        break;
      case 'falta_respeto':
        dialogTitle = 'Registrar Falta de Respeto';
        accentColor = Colors.purple;
        headerIcon = Icons.sentiment_very_dissatisfied_outlined;
        break;
      case 'falta':
      default:
        dialogTitle = 'Registrar Ausencia';
        accentColor = Colors.amber;
        headerIcon = Icons.event_busy_outlined;
        break;
    }

    // Usar BuildContext.mounted para manejar contexto
    if (!context.mounted) return;

    // Técnica diferente: usar una clase auxiliar para mostrar el diálogo
    await _showIncidentDialog(
      context: context,
      dialogTitle: dialogTitle,
      accentColor: accentColor,
      headerIcon: headerIcon,
      incidentType: incidentType,
      workerName: widget.worker.name,
      worker: widget.worker,
      currentFailures: currentFailures,
      onSuccess: (incidentType) {
        setState(() {
          currentFailures++;
        });
      },
    );
  }

// Método separado para mostrar el diálogo, lo que permite mejor manejo de recursos
  Future<void> _showIncidentDialog({
    required BuildContext context,
    required String dialogTitle,
    required Color accentColor,
    required IconData headerIcon,
    required String incidentType,
    required String workerName,
    required Worker worker,
    required int currentFailures,
    required Function(String) onSuccess,
  }) async {
    bool isProcessing = false;
    String? description;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Crear un controller dentro del builder para que viva con el diálogo
        final TextEditingController descriptionController =
            TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título con ícono
                    Row(
                      children: [
                        Icon(headerIcon, color: accentColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dialogTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isProcessing)
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[500]),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '¿Deseas registrar ${incidentType == "falta" ? "una falta" : incidentType == "abandono" ? "un abandono" : "una falta de respeto"} para $workerName?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 24),

                    // Campo para descripción del incidente
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        onChanged: (value) {
                          // Guardar valor en variable local para evitar acceder al controller después
                          description = value;
                        },
                        decoration: InputDecoration(
                          hintText: '¿Qué ocurrió? Describe el incidente...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                          contentPadding: const EdgeInsets.all(12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información sobre consecuencias
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: accentColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incidentType == 'falta'
                                      ? 'Esta será la falta número ${currentFailures + 1}'
                                      : 'Este incidente quedará registrado',
                                  style: TextStyle(
                                    color: accentColor.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'La información quedará documentada en el historial del trabajador.',
                                  style: TextStyle(
                                    color: accentColor.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: isProcessing
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        NeumorphicButton(
                          style: NeumorphicStyle(
                            depth: isProcessing ? 0 : 2,
                            intensity: 0.7,
                            color: isProcessing
                                ? accentColor.withOpacity(0.3)
                                : accentColor,
                            boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(8)),
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  // Obtener descripción de la variable local
                                  final localDescription = description;

                                  if (localDescription == null ||
                                      localDescription.trim().isEmpty) {
                                    showErrorToast(context,
                                        'Por favor describe el incidente');
                                    return;
                                  }

                                  setDialogState(() {
                                    isProcessing = true;
                                  });

                                  try {
                                    final FaultsProvider faultsProvider =
                                        Provider.of<FaultsProvider>(
                                            dialogContext,
                                            listen: false);
                                    bool success = false;

                                    // Llamar al método adecuado según el tipo de incidente
                                    switch (incidentType) {
                                      case 'abandono':
                                        success = await faultsProvider
                                            .registerAbandonment(
                                          worker,
                                          dialogContext, // Usa dialogContext en lugar de context
                                          description: localDescription,
                                        );
                                        break;
                                      case 'falta_respeto':
                                        success = await faultsProvider
                                            .registerDisrespect(
                                          worker,
                                          dialogContext, // Usa dialogContext en lugar de context
                                          description: localDescription,
                                        );
                                        break;
                                      case 'falta':
                                        success =
                                            await faultsProvider.registerFault(
                                          worker,
                                          dialogContext, // Usa dialogContext en lugar de context
                                          description: localDescription,
                                        );
                                      default:
                                        success =
                                            await faultsProvider.registerFault(
                                          worker,
                                          dialogContext, // Usa dialogContext en lugar de context
                                          description: localDescription,
                                        );
                                        break;
                                    }

                                    if (dialogContext.mounted) {
                                      if (success) {
                                        Navigator.pop(dialogContext);
                                        onSuccess(incidentType);
                                        showSuccessToast(
                                            dialogContext,
                                            incidentType == 'falta'
                                                ? 'Falta registrada correctamente'
                                                : incidentType == 'abandono'
                                                    ? 'Abandono registrado correctamente'
                                                    : 'Falta de respeto registrada correctamente');
                                      } else {
                                        setDialogState(() {
                                          isProcessing = false;
                                        });
                                        showErrorToast(dialogContext,
                                            'Error al registrar el incidente');
                                      }
                                    }
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        isProcessing = false;
                                      });
                                      showErrorToast(
                                          dialogContext, 'Error: $e');
                                    }
                                  }
                                },
                          child: Container(
                            width: 100,
                            height: 36,
                            alignment: Alignment.center,
                            child: isProcessing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Registrando',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Registrar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget para mostrar el contador de faltas de forma visual
  Widget _buildFaultCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total de faltas registradas:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getFaultLevelColor(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentFailures.toString(), // Usamos la variable local
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Barra de progreso visual
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _calculateFaultProgress(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getFaultLevelColor()),
            minHeight: 8,
          ),
        ),

        const SizedBox(height: 8),

        // Estado de las faltas
        Text(
          _getFaultLevelText(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getFaultLevelColor(),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Calcular el progreso de las faltas (0.0 a 1.0) basado en nuestra variable local
  double _calculateFaultProgress() {
    const int maxFaults =
        5; // Número máximo de faltas antes de considerarse crítico
    return (currentFailures / maxFaults).clamp(0.0, 1.0);
  }

  // Obtener el color según el nivel de faltas (usando nuestra variable local)
  Color _getFaultLevelColor() {
    if (currentFailures == 0) {
      return Colors.green;
    } else if (currentFailures <= 2) {
      return Colors.amber.shade600;
    } else if (currentFailures <= 4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Obtener el texto descriptivo según el nivel de faltas (usando nuestra variable local)
  String _getFaultLevelText() {
    if (currentFailures == 0) {
      return 'Sin faltas registradas';
    } else if (currentFailures <= 2) {
      return 'Nivel de faltas bajo';
    } else if (currentFailures <= 3) {
      return 'Nivel de faltas moderado';
    } else if (currentFailures <= 4) {
      return 'Nivel de faltas alto';
    } else {
      return 'Nivel de faltas crítico';
    }
  }

  // Resto de métodos adaptados para usar widget.worker en lugar de worker
  Widget _buildStatusSection() {
    // No mostrar esta sección para trabajadores disponibles regulares
    if (widget.worker.status == WorkerStatus.available ||
        (widget.worker.status == WorkerStatus.assigned &&
            widget.worker.endDate == null)) {
      return Container();
    }

    String title;
    IconData icon;
    Color color;
    List<Widget> rows = [];

    // Configurar según el estado
    switch (widget.worker.status) {
      case WorkerStatus.assigned:
        title = 'Información de Operación';
        icon = Icons.assignment_turned_in;
        color = Colors.amber[700]!;
        if (widget.worker.endDate != null) {
          rows.add(_buildInfoRow(
              Icons.event_available_outlined,
              'Asignado hasta',
              DateFormat('dd/MM/yyyy').format(widget.worker.endDate!)));
        }
        break;

      case WorkerStatus.incapacitated:
        title = 'Información de Incapacidad';
        icon = Icons.medical_services_outlined;
        color = Colors.purple;

        if (widget.worker.incapacityStartDate != null) {
          rows.add(_buildInfoRow(
              Icons.date_range_outlined,
              'Inicio',
              DateFormat('dd/MM/yyyy')
                  .format(widget.worker.incapacityStartDate!)));
        }

        if (widget.worker.incapacityEndDate != null) {
          rows.add(_buildInfoRow(
              Icons.date_range_outlined,
              'Fin',
              DateFormat('dd/MM/yyyy')
                  .format(widget.worker.incapacityEndDate!)));

          // Calcular días restantes
          final daysLeft = widget.worker.incapacityEndDate!
              .difference(DateTime.now())
              .inDays;
          String daysLeftText =
              daysLeft > 0 ? '${daysLeft + 1} días restantes' : 'Finalizada';

          rows.add(
              _buildInfoRow(Icons.hourglass_bottom, 'Estado', daysLeftText));
        }

        // Agregar información de tipo y causa si está disponible
        if (isLoadingIncapacity) {
          rows.add(_buildLoadingRow());
        } else if (currentIncapacity != null) {
          final incapacityProvider =
              Provider.of<IncapacityProvider>(context, listen: false);

          rows.add(_buildInfoRow(
              Icons.category_outlined,
              'Tipo',
              incapacityProvider
                  .mapTypeToDisplayString(currentIncapacity!.type)));

          rows.add(_buildInfoRow(
              Icons.healing_outlined,
              'Causa',
              incapacityProvider
                  .mapCauseToDisplayString(currentIncapacity!.cause)));
        } else {
          // Si no se pudo cargar la información, mostrar opción para recargar
          rows.add(_buildRetryRow());
        }
        break;

      case WorkerStatus.deactivated:
        title = 'Información de Retiro';
        icon = Icons.exit_to_app;
        color = Colors.grey[700]!;

        if (widget.worker.deactivationDate != null) {
          rows.add(_buildInfoRow(
              Icons.event_busy_outlined,
              'Fecha de retiro',
              DateFormat('dd/MM/yyyy')
                  .format(widget.worker.deactivationDate!)));
        }
        break;

      default:
        return Container();
    }

    // Si no hay filas, no mostrar la sección
    if (rows.isEmpty) {
      return Container();
    }

    return _buildInfoSection(
      title: title,
      icon: icon,
      color: color,
      content: rows,
    );
  }

  // Widget para mostrar loading
  Widget _buildLoadingRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Cargando detalles...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar opción de reintentar
  Widget _buildRetryRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.refresh, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'No se pudieron cargar los detalles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _loadCurrentIncapacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Los métodos _buildInfoSection e _buildInfoRow permanecen iguales
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> content,
  }) {
    // Implementación existente
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ...content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    // Implementación existente
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
