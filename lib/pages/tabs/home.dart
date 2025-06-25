import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/pages/login.dart';
import 'package:plannerop/pages/tabs/operations.dart';
import 'package:plannerop/pages/tabs/dashboard.dart';
import 'package:plannerop/pages/tabs/reports.dart';
import 'package:plannerop/pages/tabs/workers.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/utils/toast.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;

  // Registrar la última vez que se visitó cada tab
  final Map<int, DateTime> _lastVisitTimes = {};

  // Crear tabs dinámicamente con claves para controlar su estado
  late final List<Widget> _widgetOptions;

  //  GETTER PARA VERIFICAR SI ES SUPERADMIN
  bool get _isSuperAdmin {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    return user.cargo == "SUPERADMIN";
  }

  @override
  void initState() {
    super.initState();
    // Inicializar los widgets con sus claves
    _widgetOptions = [
      DashboardTab(),
      OperationsTab(),
      ReportesTab(),
      WorkersTab(),
    ];

    // Registrar el tiempo inicial para el primer tab
    _lastVisitTimes[_selectedIndex] = DateTime.now();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return true;
    }

    _lastBackPressTime = now;

    // Captura las referencias a los providers antes de mostrar el diálogo
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // IMPORTANTE: Primero cerramos el diálogo
              Navigator.of(context).pop(true);
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Mostrar un indicador de carga
      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AppLoader(
                  message: 'Cerrando sesión...',
                  color: Colors.blue,
                  size: LoaderSize.medium,
                ));
      }

      try {
        // IMPORTANTE: Usamos la referencia capturada anteriormente
        userProvider.clearUser();
        await authProvider.logout();

        // Una vez completado el logout, navegamos a la página de login
        if (mounted) {
          // IMPORTANTE: Usamos pushReplacement en lugar de pushAndRemoveUntil
          // Esto evita problemas con el contexto al desmontar widgets
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
        return true;
      } catch (e) {
        debugPrint('Error al cerrar sesión: $e');
        if (mounted) {
          // Cerrar el loader si está visible
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          showErrorToast(context, 'Error al cerrar sesión');
        }
        return false;
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Presiona atrás de nuevo para salir de la aplicación'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  void _onItemTapped(int index) {
    // Si es el mismo tab, no hacemos nada
    if (index == _selectedIndex) return;

    // Verificar si el usuario es de GESTION HUMANA y está intentando acceder a tabs restringidos
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user.role == "GH" && (index == 1 || index == 2)) {
      // Mostrar mensaje informando que no tiene permiso
      showAlertToast(context, 'No tienes permiso para acceder a este tab');
      return; // Prevenir navegación a los tabs restringidos
    }

    setState(() {
      _selectedIndex = index;

      // Registrar cuándo se visitó este tab
      _lastVisitTimes[index] = DateTime.now();

      // Actualizar datos del nuevo tab seleccionado
      _refreshTabData(index);
    });
  }

  void _refreshTabData(int tabIndex) {
    // Calcular tiempo desde la última visita
    final previousVisit = _lastVisitTimes[tabIndex];
    final now = DateTime.now();

    // Solo refrescar si es una visita nueva o ha pasado tiempo suficiente
    final needsRefresh =
        previousVisit == null || now.difference(previousVisit).inMinutes > 1;

    if (needsRefresh) {
      // Obtener el contexto después de que el frame se haya renderizado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (tabIndex == 0) {
          // Refrescar Dashboard
          _refreshDashboard();
        } else if (tabIndex == 1) {
          // Refrescar Asignaciones
          _refreshOperations();
        }
      });
    }
  }

  // Métodos específicos para refrescar cada tab
  void _refreshDashboard() {
    final assignmentsProvider =
        Provider.of<OperationsProvider>(context, listen: false);
    // Actualizar silenciosamente sin mostrar indicadores de carga
    assignmentsProvider.refreshActiveOperations(context);
  }

  void _refreshOperations() {
    final assignmentsProvider =
        Provider.of<OperationsProvider>(context, listen: false);
    // Refrescar solo asignaciones activas y pendientes
    assignmentsProvider.refreshActiveOperations(context);
  }

  //  MÉTODO PARA REFRESCAR TODOS LOS DATOS DESPUÉS DE CAMBIAR SEDE
  void _refreshAllData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final operationsProvider =
          Provider.of<OperationsProvider>(context, listen: false);
      operationsProvider.refreshActiveOperations(context);

      // Refrescar el tab actual
      _refreshTabData(_selectedIndex);

      showSuccessToast(context, 'Datos actualizados para la nueva sede');
    });
  }

  //  MÉTODO PARA MOSTRAR DIÁLOGO DE CAMBIO DE SEDE
  void _showSiteChangeDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.business, color: const Color(0xFF4299E1)),
            const SizedBox(width: 8),
            const Text('Cambiar Sede'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona la sede que deseas gestionar:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ...userProvider.availableSites
                  .map((site) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: site.id == userProvider.selectedSite?.id
                                  ? const Color(0xFF4299E1)
                                  : Colors.grey.shade300,
                              width: site.id == userProvider.selectedSite?.id
                                  ? 2
                                  : 1,
                            ),
                          ),
                          tileColor: site.id == userProvider.selectedSite?.id
                              ? const Color(0xFF4299E1).withOpacity(0.1)
                              : Colors.grey.shade50,
                          leading: Icon(
                            Icons.business,
                            color: site.id == userProvider.selectedSite?.id
                                ? const Color(0xFF4299E1)
                                : Colors.grey,
                          ),
                          title: Text(
                            site.name,
                            style: TextStyle(
                              fontWeight:
                                  site.id == userProvider.selectedSite?.id
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: site.id == userProvider.selectedSite?.id
                                  ? const Color(0xFF4299E1)
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: site.id == userProvider.selectedSite?.id
                              ? const Text(
                                  'Sede actual',
                                  style: TextStyle(
                                    color: Color(0xFF4299E1),
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          trailing: site.id == userProvider.selectedSite?.id
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF4299E1))
                              : const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                          onTap: () {
                            if (site.id != userProvider.selectedSite?.id) {
                              userProvider.setSelectedSite(site);
                              Navigator.pop(context);
                              _refreshAllData();
                            }
                          },
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        //  AGREGAR APPBAR SOLO PARA SUPERADMIN
        appBar: _isSuperAdmin
            ? AppBar(
                automaticallyImplyLeading: false,
                elevation: 2,
                backgroundColor: const Color(0xFF4299E1),
                shadowColor: Colors.black.withOpacity(0.1),
                title: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return Row(
                      children: [
                        const Icon(Icons.dashboard,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'PlannerOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (userProvider.selectedSite != null) ...[
                          const SizedBox(width: 12),
                          const Text(
                            '•',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      userProvider.selectedSite!.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                actions: [
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      if (userProvider.availableSites.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.swap_horiz,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          onPressed: () => _showSiteChangeDialog(context),
                          tooltip: 'Cambiar sede',
                        ),
                      );
                    },
                  ),
                ],
              )
            : null,
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: -3,
              intensity: 0.8,
              color: const Color(0xFF3182CE),
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              selectedFontSize: 12,
              unselectedFontSize: 10,
              items: [
                _buildNavigationItem(
                    Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildNavigationItem(
                    Icons.assignment_outlined, Icons.assignment, 'Operaciones'),
                _buildNavigationItem(Icons.insert_chart_outlined,
                    Icons.insert_chart, 'Reportes'),
                _buildNavigationItem(
                    Icons.groups_outlined, Icons.groups, 'Trabajadores'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationItem(
      IconData iconOutlined, IconData iconFilled, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(iconOutlined, size: 24),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            Icon(iconFilled, size: 24),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
