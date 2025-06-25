import 'package:flutter/material.dart';

enum LoaderSize { small, medium, large, custom }

class AppLoader extends StatelessWidget {
  final String? message;
  final Color? color;
  final LoaderSize size;
  final double? customSize;
  final double? strokeWidth;
  final bool showAsScaffold;
  final Color? backgroundColor;
  final TextStyle? messageStyle;

  const AppLoader({
    Key? key,
    this.message,
    this.color,
    this.size = LoaderSize.medium,
    this.customSize,
    this.strokeWidth,
    this.showAsScaffold = false,
    this.backgroundColor,
    this.messageStyle,
  }) : super(key: key);

  //  FACTORY CONSTRUCTORS PARA CASOS COMUNES
  factory AppLoader.small({
    Color? color,
    String? message,
  }) =>
      AppLoader(
        size: LoaderSize.small,
        color: color,
        message: message,
      );

  factory AppLoader.medium({
    Color? color,
    String? message,
  }) =>
      AppLoader(
        size: LoaderSize.medium,
        color: color,
        message: message,
      );

  factory AppLoader.large({
    Color? color,
    String? message,
  }) =>
      AppLoader(
        size: LoaderSize.large,
        color: color,
        message: message,
      );

  factory AppLoader.custom({
    required double size,
    Color? color,
    String? message,
    double? strokeWidth,
  }) =>
      AppLoader(
        size: LoaderSize.custom,
        customSize: size,
        color: color,
        message: message,
        strokeWidth: strokeWidth,
      );

  factory AppLoader.fullScreen({
    String? message,
    Color? color,
    Color? backgroundColor,
  }) =>
      AppLoader(
        size: LoaderSize.large,
        message: message,
        color: color,
        showAsScaffold: true,
        backgroundColor: backgroundColor,
      );

  @override
  Widget build(BuildContext context) {
    final loaderWidget = _buildLoader(context);

    if (showAsScaffold) {
      return Scaffold(
        backgroundColor: backgroundColor ?? Colors.transparent,
        body: loaderWidget,
      );
    }

    return loaderWidget;
  }

  Widget _buildLoader(BuildContext ctx) {
    final loaderSize = _getLoaderSize();
    final effectiveStrokeWidth = strokeWidth ?? (loaderSize * 0.1);
    final effectiveColor = color ?? Theme.of(ctx).primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: loaderSize,
            height: loaderSize,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              strokeWidth: effectiveStrokeWidth,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: _getMessageSpacing()),
            Text(
              message!,
              style: messageStyle ?? _getDefaultMessageStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  double _getLoaderSize() {
    switch (size) {
      case LoaderSize.small:
        return 20.0;
      case LoaderSize.medium:
        return 32.0;
      case LoaderSize.large:
        return 48.0;
      case LoaderSize.custom:
        return customSize ?? 32.0;
    }
  }

  double _getMessageSpacing() {
    switch (size) {
      case LoaderSize.small:
        return 8.0;
      case LoaderSize.medium:
        return 12.0;
      case LoaderSize.large:
        return 16.0;
      case LoaderSize.custom:
        return (customSize ?? 32.0) * 0.3;
    }
  }

  TextStyle _getDefaultMessageStyle() {
    switch (size) {
      case LoaderSize.small:
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          decoration: TextDecoration.none,
        );
      case LoaderSize.medium:
        return const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          decoration: TextDecoration.none,
        );
      case LoaderSize.large:
        return const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.7,
          decoration: TextDecoration.none,
        );
      case LoaderSize.custom:
        return const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          decoration: TextDecoration.none,
        );
    }
  }
}
