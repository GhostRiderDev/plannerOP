import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/hooks/loaders/loader.dart';
import 'package:plannerop/pages/siteSelector.dart';
import 'package:plannerop/pages/home.dart';
import 'package:plannerop/services/auth/authStorageService.dart';
import 'package:plannerop/providers/auth.dart';
import 'package:plannerop/providers/user.dart';

import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';

Future<void> tryAutoLogin(bool mounted, Function setState, bool _isLoading,
    BuildContext context) async {
  if (!mounted) return;

  Timer? timeoutTimer;

  setState(() {
    _isLoading = true;
  });

  timeoutTimer = Timer(const Duration(seconds: 8), () {
    if (mounted && _isLoading) {
      debugPrint('AutoLogin timeout: cancelando operación');
      setState(() {
        _isLoading = false;
      });
    }
  });

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool success = await authProvider.tryAutoLogin(context);

    timeoutTimer.cancel();

    if (!mounted) return;

    if (success) {
      final decodedToken = JwtDecoder.decode(authProvider.accessToken);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authStorageService = new AuthStorageService();
      userProvider.setUser(User.fromJson(decodedToken));

      if (userProvider.user.role != "SUPERVISOR") {
        try {
          final SiteSelector siteSelector = SiteSelector();
          await siteSelector.handleSiteSelection(context);

          // VERIFICAR QUE REALMENTE SE SELECCIONÓ UN SITE
          if (userProvider.selectedSite == null) {
            debugPrint('❌ No se seleccionó sede durante auto-login');

            //  LIMPIAR CREDENCIALES PARA EVITAR BUCLE DE ERROR
            await authStorageService.clearCredentials();

            if (mounted) {
              showErrorToast(context, 'Debe seleccionar una sede principal');
              setState(() {
                _isLoading = false;
              });
            }
            return;
          }
        } catch (siteSelectionError) {
          debugPrint('❌ Error en selección de sede: $siteSelectionError');

          //  SI HAY ERROR DE ENCRIPTACIÓN, LIMPIAR CREDENCIALES
          if (siteSelectionError
              .toString()
              .contains('Invalid or corrupted pad block')) {
            debugPrint(
                '🧹 Detectado error de encriptación, limpiando credenciales');
            await authStorageService.clearCredentials();
          }

          if (mounted) {
            showErrorToast(context,
                'Error al seleccionar sede. Por favor inicie sesión manualmente.');
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        final siteId = userProvider.selectedSite!.id;
        final subsiteId = userProvider.selectedSubsite?.id;

        //  MOSTRAR LOADER PARA REFRESCAR TOKEN
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AppLoader(
                message: 'Configurando sede seleccionada...',
                color: Colors.blue,
                size: LoaderSize.medium,
              );
            },
          );
        }

        //  REFRESCO DE TOKEN CON AWAIT PARA ESPERAR RESPUESTA
        final refreshSuccess =
            await authProvider.refreshToken(siteId, subsiteId, context);

        // Cerrar loader de configuración
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (!refreshSuccess) {
          if (mounted) {
            showErrorToast(context, 'Error al configurar la sede seleccionada');
          }
          return;
        }
      }
      //  MOSTRAR LOADER DESPUÉS DE SELECCIONAR SEDE
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text(
                          'Cargando datos...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (userProvider.selectedSite != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Sede: ${userProvider.selectedSite!.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      // Cargar datos
      try {
        try {
          await loadDataAfterAuthentication(
            context,
            isMounted: () => mounted,
          );
        } catch (dataError) {
          debugPrint('Error cargando datos: $dataError');
        }
      } catch (dataError) {
        debugPrint('Error cargando datos: $dataError');
      }

      // Navegar al dashboard
      if (mounted) {
        if (ModalRoute.of(context)?.isCurrent != true) {
          Navigator.of(context).pop();
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }
    }
  } catch (e) {
    debugPrint('Error en auto-login: $e');
    timeoutTimer.cancel();
  } finally {
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Future<void> login(GlobalKey<FormState> _formKey, BuildContext context,
    bool mounted, String username, String password) async {
  if (_formKey.currentState!.validate()) {
    bool dialogIsOpen = true;
    BuildContext? dialogContextRef;

    // MOSTRAR LOADER DE LOGIN
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        dialogContextRef = dialogContext;
        return AppLoader(
          message: 'Iniciando sesión, por favor espere...',
          color: Colors.blue,
          size: LoaderSize.medium,
        );
      },
    );

    void closeDialog() {
      if (dialogIsOpen && mounted && dialogContextRef != null) {
        Navigator.of(dialogContextRef!).pop();
        dialogIsOpen = false;
      }
    }

    Future.delayed(const Duration(seconds: 15), () {
      if (dialogIsOpen) {
        closeDialog();
        if (mounted) {
          showAlertToast(
              context, 'La operación está tardando demasiado tiempo');
        }
      }
    });

    try {
      var authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(username, password, context);

      if (success) {
        final decodedToken = JwtDecoder.decode(authProvider.accessToken);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        userProvider.setUser(User.fromJson(decodedToken));

        // CERRAR LOADER DE LOGIN ANTES DE MOSTRAR SELECTOR
        closeDialog();

        if (userProvider.user.role != "SUPERVISOR") {
          //  INICIAR SELECCIÓN DE SITE Y SUBSITE
          final SiteSelector siteSelector = SiteSelector();
          await siteSelector.handleSiteSelection(context);

          //  VERIFICAR QUE REALMENTE SE SELECCIONÓ UN SITE
          if (userProvider.selectedSite == null) {
            if (mounted) {
              showErrorToast(context, 'Debe seleccionar una sede principal');
            }
            return;
          }

          final siteId = userProvider.selectedSite!.id;
          final subsiteId = userProvider.selectedSubsite?.id;

          //  MOSTRAR LOADER PARA REFRESCAR TOKEN
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AppLoader(
                  message: 'Configurando sede seleccionada...',
                  color: Colors.blue,
                  size: LoaderSize.medium,
                );
              },
            );
          }

          //  REFRESCO DE TOKEN CON AWAIT PARA ESPERAR RESPUESTA
          final refreshSuccess =
              await authProvider.refreshToken(siteId, subsiteId, context);

          // Cerrar loader de configuración
          if (mounted) {
            Navigator.of(context).pop();
          }

          if (!refreshSuccess) {
            if (mounted) {
              showErrorToast(
                  context, 'Error al configurar la sede seleccionada');
            }
            return;
          }
        }

        //  MOSTRAR LOADER DE CARGA DE DATOS
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AppLoader(
                message: 'Cargando datos, por favor espere...',
                color: Colors.blue,
                size: LoaderSize.medium,
              );
            },
          );
        }

        // Cargar datos
        try {
          await loadDataAfterAuthentication(
            context,
            isMounted: () => mounted,
          );
        } catch (e) {
          debugPrint('❌ Error cargando datos: $e');
        }

        // Navegar al dashboard
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar loader de datos
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      } else {
        closeDialog();
        if (mounted) {
          showErrorToast(
              context, authProvider.error ?? 'Error de autenticación');
        }
      }
    } catch (e) {
      closeDialog();
      if (mounted) {
        showErrorToast(context, 'Error de conexión: $e');
      }
    }
  }
}
