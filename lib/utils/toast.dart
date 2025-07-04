import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showSuccessToast(BuildContext context, String message) {
  // Verificar que el contexto esté montado antes de mostrar el toast
  if (!context.mounted) {
    debugPrint('Context not mounted, skipping toast: $message');
    return;
  }

  try {
    // Usar el toast nativo en lugar del overlay
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } catch (e) {
    debugPrint('Error showing success toast: $e');
    // Fallback a SnackBar si el toast falla
    _showSnackBarFallback(context, message, Colors.green);
  }
}

void showErrorToast(BuildContext context, String message) {
  if (!context.mounted) {
    debugPrint('Context not mounted, skipping toast: $message');
    return;
  }

  try {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } catch (e) {
    debugPrint('Error showing error toast: $e');
    _showSnackBarFallback(context, message, Colors.red);
  }
}

void showAlertToast(BuildContext context, String message) {
  if (!context.mounted) {
    debugPrint('Context not mounted, skipping toast: $message');
    return;
  }

  try {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } catch (e) {
    debugPrint('Error showing alert toast: $e');
    _showSnackBarFallback(context, message, Colors.orange);
  }
}

void showInfoToast(BuildContext context, String message) {
  if (!context.mounted) {
    debugPrint('Context not mounted, skipping toast: $message');
    return;
  }

  try {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } catch (e) {
    debugPrint('Error showing info toast: $e');
    _showSnackBarFallback(context, message, Colors.blue);
  }
}

// Función fallback para usar SnackBar cuando el toast falla
void _showSnackBarFallback(BuildContext context, String message, Color color) {
  try {
    if (context.mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error showing SnackBar fallback: $e');
  }
}
