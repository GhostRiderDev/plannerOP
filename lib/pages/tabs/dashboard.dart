import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/hooks/loaders/loader.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/dashboard/quickActions.dart';
import 'package:plannerop/widgets/dashboard/recentOps.dart';
import 'package:provider/provider.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoadingWorkers = false;
  bool _isLoadingAreas = false;
  bool _isLoadingTasks = false;
  bool _isLoadingClients = false;
  bool _isLoadingAssignments = false;
  bool _isLoadingFaults = false;
  bool _isLoadingChargers = false;
  bool _isLoadingClientProgramming = false;
  // Variable para controlar si es la primera carga
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para programar la carga después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAllData();
      _isInitialLoad = false;
    });
  }

  // Método unificado para cargar todos los datos
  Future<void> _loadAllData({bool forceRefresh = false}) async {
    if (!mounted) return;

    try {
      // Actualizar estados de carga
      setState(() {
        _isLoadingWorkers = true;
        _isLoadingAreas = true;
        _isLoadingTasks = true;
        _isLoadingClients = true;
        _isLoadingAssignments = true;
        _isLoadingFaults = true;
        _isLoadingChargers = true;
        _isLoadingClientProgramming = true;
      });

      // Cargar todos los datos en paralelo
      await Future.wait([
        loadTask(
          () => mounted,
          setState,
          _isLoadingTasks,
          context,
        ),
        checkAndLoadWorkersIfNeeded(
          () => mounted,
          setState,
          _isLoadingWorkers,
          context,
        ),
        loadAreas(
          () => mounted,
          setState,
          _isLoadingAreas,
          context,
        ),
        loadClients(
          () => mounted,
          setState,
          _isLoadingClients,
          context,
        ),
        loadAssignments(
          context: context,
          isMounted: () => mounted,
          setStateCallback: (fn) {
            if (mounted) setState(fn);
          },
          updateLoadingState: (isLoading) {
            _isLoadingAssignments = isLoading;
          },
        ),
        loadFaults(
          context: context,
          isMounted: () => mounted,
          setStateCallback: (fn) {
            if (mounted) setState(fn);
          },
          updateLoadingState: (isLoading) {
            _isLoadingFaults = isLoading;
          },
        ),
        loadChargersOp(
          context: context,
          isMounted: () => mounted,
          setStateCallback: (fn) {
            if (mounted) setState(fn);
          },
          updateLoadingState: (isLoading) {
            _isLoadingChargers = isLoading;
          },
        ),
        loadClientProgramming(
            () => mounted, setState, _isLoadingClientProgramming, context,
            forceRefresh: forceRefresh)
      ]).catchError((error) {
        debugPrint('Error durante la carga en paralelo: $error');
        if (mounted) {
          showErrorToast(context, 'Error al cargar algunos datos');
        }
      });

      if (mounted && forceRefresh) {
        showSuccessToast(context, 'Datos actualizados correctamente');
      }
    } catch (e) {
      debugPrint('Error general en _loadAllData: $e');
      if (mounted) {
        showErrorToast(context, 'Error al cargar datos: $e');
      }
    } finally {
      // Asegurar que todos los estados de carga se desactiven
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
          _isLoadingAreas = false;
          _isLoadingTasks = false;
          _isLoadingClients = false;
          _isLoadingAssignments = false;
          _isLoadingFaults = false;
          _isLoadingChargers = false;
          _isLoadingClientProgramming = false;
        });

        // Asegurar que los providers también deshabiliten sus indicadores
        try {
          Provider.of<OperationsProvider>(context, listen: false)
              .changeIsLoadingOff();
        } catch (e) {
          debugPrint('Error al desactivar loading del provider: $e');
        }
      }
    }
  }

  // Método para verificar si algún dato está cargando
  bool get _isAnyLoading {
    return _isLoadingWorkers ||
        _isLoadingAreas ||
        _isLoadingTasks ||
        _isLoadingClients ||
        _isLoadingAssignments ||
        _isLoadingFaults ||
        _isLoadingChargers ||
        _isLoadingClientProgramming;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nueva cabecera elegante con gradiente
          Container(
            padding: EdgeInsets.fromLTRB(20, 20 + statusBarHeight, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior con título y botón de actualización
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        // Indicador de carga si es necesario
                        if (_isAnyLoading)
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 20,
                            height: 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        // Botón de actualización
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _isAnyLoading
                              ? null
                              : () async {
                                  // Usar el método unificado para refrescar
                                  await _loadAllData(forceRefresh: true);
                                },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Subtítulo
                Text(
                  'Resumen de tus operaciones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 15),

                // Tarjeta de resumen rápido
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Operaciones pendientes
                      _buildQuickStatItem(
                          context,
                          Icons.pending_actions_outlined,
                          'Pendientes',
                          Provider.of<OperationsProvider>(context)
                              .pendingOperations
                              .length
                              .toString()),
                      // Contador de operaciones en curso
                      _buildQuickStatItem(
                          context,
                          Icons.directions_run,
                          'En Curso',
                          Provider.of<OperationsProvider>(context)
                              .inProgressOperations
                              .length
                              .toString()),
                      // Contador de asignaciones finalizadas
                      _buildQuickStatItem(
                          context,
                          Icons.check_circle_outline,
                          'Finalizadas',
                          Provider.of<OperationsProvider>(context)
                              .completedOperations
                              .where((a) =>
                                  a.endDate?.month == DateTime.now().month &&
                                  a.endDate?.day == DateTime.now().day &&
                                  a.endDate?.year == DateTime.now().year)
                              .length
                              .toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido del dashboard
          Expanded(
            child: (_isInitialLoad && _isAnyLoading)
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Cargando datos...',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      // Usar el método unificado para el pull-to-refresh
                      await _loadAllData(forceRefresh: true);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            QuickActions(),
                            const SizedBox(height: 24),
                            RecentOps(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar un elemento de estadística rápida
  Widget _buildQuickStatItem(
      BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
