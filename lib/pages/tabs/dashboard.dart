import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/hooks/loaders/loader.dart';
import 'package:plannerop/pages/siteSelector.dart';
import 'package:plannerop/providers/auth.dart';
import 'package:plannerop/providers/operations.dart';
import 'package:plannerop/providers/user.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/dashboard/quickActions.dart';
import 'package:plannerop/widgets/dashboard/recentOps.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
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

    final User user = Provider.of<UserProvider>(context, listen: false).user;

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
          isMounted: () => mounted,
          setState: setState,
          isLoadingTasks: _isLoadingTasks,
          context: context,
        ),
        checkAndLoadWorkersIfNeeded(
          isMounted: () => mounted,
          setState: setState,
          isLoadingWorkers: _isLoadingWorkers,
          context: context,
        ),
        loadAreas(
          isMounted: () => mounted,
          setState: setState,
          isLoadingAreas: _isLoadingAreas,
          context: context,
        ),
        loadClients(
          isMounted: () => mounted,
          setState: setState,
          isLoadingClients: _isLoadingClients,
          context: context,
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
        if (user.role != "GH")
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
        if (user.role != "GH")
          loadClientProgramming(
              isMounted: () => mounted,
              setState: setState,
              isLoadingClientProgramming: _isLoadingClientProgramming,
              context: context,
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

  Future<void> _changeSite() async {
    try {
      // Mostrar diálogo de confirmación
      final shouldChange = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambiar Sede'),
          content: const Text(
              '¿Deseas cambiar la sede actual? Esto requerirá reconfigurar tus datos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );

      if (shouldChange != true) return;

      // Mostrar loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AppLoader(
          message: 'Cambiando sede...',
          color: Colors.blue,
          size: LoaderSize.medium,
        ),
      );

      //  USAR MÉTODO SIMPLE: Limpiar + Seleccionar + Recargar
      await _performSiteChange();

      // Cerrar loader
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Sede cambiada exitosamente');
      }
    } catch (e) {
      // Cerrar cualquier loader abierto
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        showErrorToast(context, 'Error al cambiar sede: $e');
      }
    }
  }

  //  MÉTODO SIMPLE QUE REUTILIZA LA LÓGICA EXISTENTE
  Future<void> _performSiteChange() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 1. Limpiar datos usando la función existente del AuthProvider
    await authProvider
        .clearProvidersData(); // Reutilizar la limpieza del logout

    // 2. Seleccionar nueva sede
    final siteSelector = SiteSelector();
    await siteSelector.handleSiteSelection(context);

    // 3. Verificar selección
    if (userProvider.selectedSite == null) {
      throw Exception('No se seleccionó ninguna sede');
    }

    // 4. Refrescar token con nueva sede
    final siteId = userProvider.selectedSite!.id;
    final subsiteId = userProvider.selectedSubsite?.id;

    final refreshSuccess =
        await authProvider.refreshToken(siteId, subsiteId, context);
    if (!refreshSuccess) {
      throw Exception('Error al configurar la nueva sede');
    }

    // 5. Recargar datos usando tu función existente
    await _loadAllData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    final userProvider = Provider.of<UserProvider>(context);

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
                        if (userProvider.user.role != "SUPERVISOR")
                          IconButton(
                            icon: const Icon(Icons.swap_horiz,
                                color: Colors.white),
                            onPressed: _isAnyLoading ? null : _changeSite,
                            tooltip: userProvider.user.role == "SUPERADMIN"
                                ? 'Cambiar Sede'
                                : 'Cambiar Sub-Sede',
                          ),
                        // Indicador de carga si es necesario
                        if (_isAnyLoading)
                          AppLoader(
                            color: Colors.white,
                            size: LoaderSize.small,
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
                ? AppLoader(
                    color: Colors.white,
                    size: LoaderSize.small,
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
