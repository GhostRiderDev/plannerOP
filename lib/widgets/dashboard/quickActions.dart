import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/pages/tabs/operations.dart';
import 'package:plannerop/pages/tabs/reports.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/widgets/operations/add/addOperationDialog.dart';
import 'package:provider/provider.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context, listen: false).user;

    return user.role != "GH"
        ? Neumorphic(
            style: NeumorphicStyle(
              depth: 3,
              intensity: 0.5,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
              color: const Color.fromARGB(255, 234, 241, 245),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded,
                          color: Color(0xFF4299E1), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Acciones Rápidas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Fila de acciones rápidas
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 75,
                          child: NeumorphicButton(
                            onPressed: () {
                              // Acción para crear nueva operación
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    const AddOperationDialog(),
                              );
                            },
                            style: NeumorphicStyle(
                              shape: NeumorphicShape.flat,
                              depth: 6,
                              intensity: 0.6,
                              lightSource: LightSource.topLeft,
                              color: const Color(0xFF3182CE),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(12)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.person_add,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Asignar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 75,
                          child: NeumorphicButton(
                            onPressed: () {
                              // Navegar a la pestaña de asignaciones
                              _navigateToTab(
                                  context, 1); // Índice 1 = Asignaciones
                            },
                            style: NeumorphicStyle(
                              shape: NeumorphicShape.flat,
                              depth: 6,
                              intensity: 0.6,
                              lightSource: LightSource.topLeft,
                              color: const Color(0xFF2F855A),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(12)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.visibility,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Ver Operaciones',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 75,
                          child: NeumorphicButton(
                            onPressed: () {
                              // Navegar a la pestaña de reportes
                              _navigateToTab(context, 2); // Índice 2 = Reportes
                            },
                            style: NeumorphicStyle(
                              shape: NeumorphicShape.flat,
                              depth: 6,
                              intensity: 0.6,
                              lightSource: LightSource.topLeft,
                              color: const Color(0xFFDD6B20),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(12)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.description,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Generar Reporte',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    // Buscar el SupervisorHome y cambiar la pestaña
    final scaffold = Scaffold.of(context);

    // Buscar el widget padre NavigatorState
    final navigator = Navigator.of(context);

    // Cerrar el drawer si está abierto
    if (scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }

    // Navegar a la página específica
    if (tabIndex == 1) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const OperationsTab()),
      );
    } else if (tabIndex == 2) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const ReportesTab()),
      );
    }
  }
}
