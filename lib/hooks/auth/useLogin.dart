import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/hooks/loaders/loader.dart';
import 'package:plannerop/pages/siteSlector.dart';
import 'package:plannerop/pages/tabs/home.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';

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

      userProvider.setUser(User(
        name: decodedToken['username'],
        id: decodedToken['id'],
        dni: decodedToken['dni'],
        phone: decodedToken['phone'],
        cargo: decodedToken['occupation'],
        role: decodedToken['role'],
      ));

      debugPrint(
          "Usuario autenticado: ${userProvider.user.name} (${userProvider.user.role})");

      final SiteSelector siteSelector = SiteSelector();

      //  MANEJAR SELECCIÓN DE SEDE
      await siteSelector.handleSiteSelection(context);

      //  MOSTRAR LOADER DESPUÉS DE SELECCIONAR SEDE
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

    //  MOSTRAR LOADER DE LOGIN
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(username, password, context);

      if (success) {
        final decodedToken = JwtDecoder.decode(authProvider.accessToken);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        userProvider.setUser(User(
          name: decodedToken['username'],
          id: decodedToken['id'],
          dni: decodedToken['dni'],
          phone: decodedToken['phone'],
          cargo: decodedToken['occupation'],
          role: decodedToken['role'],
        ));

        //  CERRAR LOADER DE LOGIN ANTES DE MOSTRAR SELECTOR
        closeDialog();

        final SiteSelector siteSelector = SiteSelector();

        //  MANEJAR SELECCIÓN DE SEDE
        await siteSelector.handleSiteSelection(context);

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
        await loadDataAfterAuthentication(
          context,
          isMounted: () => mounted,
        );

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
