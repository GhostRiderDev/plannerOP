import 'package:flutter/material.dart';
import 'package:plannerop/core/model/site.dart';
import 'package:plannerop/services/sites/sites.dart';
import 'package:plannerop/providers/user.dart';
import 'package:provider/provider.dart';

class SiteSelector {
  final SiteService _siteService = SiteService();

  /// Función principal para manejar la selección de sede
  Future<void> handleSiteSelection(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Solo mostrar para superadmin
    if (userProvider.user.role != "SUPERADMIN" &&
        userProvider.user.role != "ADMIN") return;

    // Cargar sedes disponibles
    final sites = await _loadAvailableSites(context);

    if (sites.isEmpty) return;

    // Configurar sedes disponibles
    userProvider.setAvailableSites(sites);

    // Mostrar selector
    final selectedSite = await _showSiteSelector(context, sites);

    if (selectedSite != null) {
      userProvider.setSelectedSite(selectedSite);
      if (selectedSite.subSites.isNotEmpty) {
        final selectedSubSite =
            await _showSiteSelector(context, selectedSite.subSites);
        userProvider.setSelectedSubsite(selectedSubSite);
      }
    }
  }

  /// Cargar sedes disponibles (reemplazar con tu API)
  Future<List<Site>> _loadAvailableSites(BuildContext context) async {
    try {
      final sites = await _siteService.getAllSites(context);

      return sites.map((site) {
        // Verificar que el site tenga las propiedades esperadas
        final id = site['id'] ?? 0;
        final name = site['name'] ?? 'Sin nombre';

        // Manejar subSites con seguridad
        List<Site> subSites = [];
        if (site['SubSite'] != null && site['SubSite'] is List) {
          try {
            subSites = (site['SubSite'] as List).map((subSite) {
              return Site(
                id: subSite['id'] ?? 0,
                name: subSite['name'] ?? 'Sin nombre',
                subSites: [],
              );
            }).toList();
          } catch (e) {
            debugPrint('Error al procesar subSites: $e');
          }
        }

        return Site(
          id: id,
          name: name,
          subSites: subSites,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error al cargar sites: $e');
      return [];
    }
  }

  /// Mostrar el diálogo de selección de sede
  Future<Site?> _showSiteSelector(
      BuildContext context, List<Site> sites) async {
    return showDialog<Site>(
      context: context,
      barrierDismissible: false,
      //  USAR WillPopScope PARA EVITAR CERRAR CON BACK
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Evitar cerrar con botón atrás
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.business_center,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Seleccionar Sede',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Como SuperAdmin, selecciona la sede a gestionar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ✅ CONTENIDO DEL DIÁLOGO
                Flexible(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 400,
                      minWidth: 300,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: sites.length,
                            itemBuilder: (context, index) {
                              final site = sites[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.pop(context, site),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4299E1)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.business,
                                              color: const Color(0xFF4299E1),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  site.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
