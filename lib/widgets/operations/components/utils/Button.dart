import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

enum AppButtonType {
  primary,
  secondary,
  success,
  warning,
  danger,
  neutral,
  outlined,
  text,
}

enum AppButtonSize { small, medium, large, extraLarge, longer }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? customChild;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customChild,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  // Factory constructors para tipos específicos
  factory AppButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.medium,
  }) =>
      AppButton(
        text: text,
        onPressed: onPressed,
        type: AppButtonType.primary,
        icon: icon,
        isLoading: isLoading,
        isFullWidth: isFullWidth,
        size: size,
      );

  factory AppButton.secondary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.medium,
  }) =>
      AppButton(
        text: text,
        onPressed: onPressed,
        type: AppButtonType.secondary,
        icon: icon,
        isLoading: isLoading,
        isFullWidth: isFullWidth,
        size: size,
      );

  factory AppButton.danger({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.medium,
  }) =>
      AppButton(
        text: text,
        onPressed: onPressed,
        type: AppButtonType.danger,
        icon: icon,
        isLoading: isLoading,
        isFullWidth: isFullWidth,
        size: size,
      );

  factory AppButton.success({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.medium,
  }) =>
      AppButton(
        text: text,
        onPressed: onPressed,
        type: AppButtonType.success,
        icon: icon,
        isLoading: isLoading,
        isFullWidth: isFullWidth,
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    final config = _getButtonConfig();
    Widget child = customChild ?? _buildButtonContent(config);

    if (isFullWidth) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4), // ESTO SÍ FUNCIONA
        child: _buildButtonWidget(config, child),
      );
    }

    return _buildButtonWidget(config, child);
  }

  Widget _buildButtonWidget(ButtonConfig config, Widget child) {
    final bool isDisabled = isLoading || onPressed == null;

    // Para botones de texto, usar InkWell simple
    if (type == AppButtonType.text) {
      return InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius:
            borderRadius ?? BorderRadius.circular(config.borderRadius),
        child: Container(
          padding: padding ?? config.padding,
          child: child,
        ),
      );
    }

    // Para botones outlined, usar Container con border
    if (type == AppButtonType.outlined) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius:
              borderRadius ?? BorderRadius.circular(config.borderRadius),
          child: Container(
            padding: padding ?? config.padding,
            decoration: BoxDecoration(
              color: config.backgroundColor,
              border: Border.all(
                color: isDisabled
                    ? config.textColor.withOpacity(0.3)
                    : config.textColor,
                width: 1.5,
              ),
              borderRadius:
                  borderRadius ?? BorderRadius.circular(config.borderRadius),
            ),
            child: child,
          ),
        ),
      );
    }

    // Para botones normales, usar Material con elevación
    return Material(
      elevation: isDisabled ? 0 : config.elevation,
      shadowColor: config.backgroundColor.withOpacity(0.3),
      borderRadius: borderRadius ?? BorderRadius.circular(config.borderRadius),
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius:
            borderRadius ?? BorderRadius.circular(config.borderRadius),
        splashColor: config.textColor.withOpacity(0.1),
        highlightColor: config.textColor.withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: isDisabled
                ? config.backgroundColor.withOpacity(0.6)
                : config.backgroundColor,
            borderRadius:
                borderRadius ?? BorderRadius.circular(config.borderRadius),
            gradient: config.gradient, // Gradientes opcionales
          ),
          child: Container(
            padding: padding ?? config.padding,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(ButtonConfig config) {
    final List<Widget> children = [];

    if (isLoading) {
      children.add(
        SizedBox(
          width: config.iconSize,
          height: config.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
          ),
        ),
      );
      if (text.isNotEmpty) {
        children.add(SizedBox(width: config.spacing));
        children.add(
          Text(
            'Cargando...',
            style: TextStyle(
              color: config.textColor.withOpacity(0.7),
              fontSize: config.fontSize,
              fontWeight: config.fontWeight,
            ),
          ),
        );
      }
    } else {
      if (icon != null) {
        children.add(
          Icon(
            icon,
            size: config.iconSize,
            color: config.textColor,
          ),
        );
        if (text.isNotEmpty) {
          children.add(SizedBox(width: config.spacing));
        }
      }

      if (text.isNotEmpty) {
        children.add(
          Text(
            text,
            style: TextStyle(
              color: config.textColor,
              fontSize: config.fontSize,
              fontWeight: config.fontWeight,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  ButtonConfig _getButtonConfig() {
    switch (type) {
      case AppButtonType.primary:
        return ButtonConfig.primary(size);
      case AppButtonType.secondary:
        return ButtonConfig.secondary(size);
      case AppButtonType.success:
        return ButtonConfig.success(size);
      case AppButtonType.warning:
        return ButtonConfig.warning(size);
      case AppButtonType.danger:
        return ButtonConfig.danger(size);
      case AppButtonType.neutral:
        return ButtonConfig.neutral(size);
      case AppButtonType.outlined:
        return ButtonConfig.outlined(size);
      case AppButtonType.text:
        return ButtonConfig.text(size);
    }
  }
}

class ButtonConfig {
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;
  final double iconSize;
  final double spacing;
  final Gradient? gradient;

  const ButtonConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
    required this.fontWeight,
    required this.padding,
    required this.borderRadius,
    required this.elevation,
    required this.iconSize,
    required this.spacing,
    this.gradient,
  });

  factory ButtonConfig.primary(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: const Color(0xFF3182CE),
      textColor: Colors.white,
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w600,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 2,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
      gradient: const LinearGradient(
        colors: [Colors.blue, Color.fromARGB(255, 75, 139, 235)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  factory ButtonConfig.secondary(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: Colors.white,
      textColor: const Color(0xFF4A5568),
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w600,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 1,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
    );
  }

  factory ButtonConfig.success(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: const Color(0xFF38A169),
      textColor: Colors.white,
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w600,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 2,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
      gradient: const LinearGradient(
        colors: [Color(0xFF38A169), Color(0xFF2F855A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  factory ButtonConfig.danger(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: const Color(0xFFFF474D),
      textColor: Colors.white,
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w600,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 2,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
    );
  }

  factory ButtonConfig.warning(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: const Color(0xFFDD6B20),
      textColor: Colors.white,
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w600,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 2,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
      gradient: const LinearGradient(
        colors: [Color(0xFFDD6B20), Color(0xFFC05621)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  factory ButtonConfig.neutral(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: const Color(0xFFF7FAFC),
      textColor: const Color(0xFF718096),
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w600,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 1,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
    );
  }

  factory ButtonConfig.outlined(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: Colors.transparent,
      textColor: const Color(0xFF3182CE),
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w600,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 0,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
    );
  }

  factory ButtonConfig.text(AppButtonSize size) {
    final sizeConfig = _getSizeConfig(size);
    return ButtonConfig(
      backgroundColor: Colors.transparent,
      textColor: const Color(0xFF3182CE),
      fontSize: sizeConfig.fontSize,
      fontWeight: FontWeight.w500,
      padding: sizeConfig.padding,
      borderRadius: 8,
      elevation: 0,
      iconSize: sizeConfig.iconSize,
      spacing: sizeConfig.spacing,
    );
  }

  static SizeConfig _getSizeConfig(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return const SizeConfig(
          fontSize: 12,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          iconSize: 16,
          spacing: 6,
        );
      case AppButtonSize.medium:
        return const SizeConfig(
          fontSize: 14,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          iconSize: 18,
          spacing: 8,
        );
      case AppButtonSize.large:
        return const SizeConfig(
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          iconSize: 20,
          spacing: 10,
        );
      case AppButtonSize.extraLarge:
        return const SizeConfig(
          fontSize: 18,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          iconSize: 24,
          spacing: 12,
        );
      case AppButtonSize.longer:
        return const SizeConfig(
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
          iconSize: 20,
          spacing: 10,
        );
    }
  }
}

class SizeConfig {
  final double fontSize;
  final EdgeInsets padding;
  final double iconSize;
  final double spacing;

  const SizeConfig({
    required this.fontSize,
    required this.padding,
    required this.iconSize,
    required this.spacing,
  });
}
