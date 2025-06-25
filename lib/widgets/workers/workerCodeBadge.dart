import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para mostrar el código del trabajador con estilo de badge
/// Incluye funcionalidad para copiar el código al portapapeles
class WorkerCodeBadge extends StatefulWidget {
  final String code;
  final bool showCopyButton;
  final Color? textColor;
  final Color? backgroundColor;

  const WorkerCodeBadge({
    Key? key,
    required this.code,
    this.showCopyButton = true,
    this.textColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<WorkerCodeBadge> createState() => _WorkerCodeBadgeState();
}

class _WorkerCodeBadgeState extends State<WorkerCodeBadge> {
  bool _copied = false;

  void _copyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code)).then((_) {
      setState(() {
        _copied = true;
      });

      // Reiniciar el estado después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _copied = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        widget.backgroundColor ?? Colors.white.withOpacity(0.2);
    final Color txtColor = widget.textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: txtColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de identificación
          Icon(
            Icons.badge_outlined,
            size: 16,
            color: txtColor.withOpacity(0.9),
          ),
          const SizedBox(width: 5),

          // Código con formato
          Text(
            widget.code,
            style: TextStyle(
              color: txtColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Monospace',
              letterSpacing: 0.5,
            ),
          ),

          // Botón de copiar (si está habilitado)
          if (widget.showCopyButton) ...[
            const SizedBox(width: 5),
            InkWell(
              onTap: _copyCodeToClipboard,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: _copied
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: txtColor.withOpacity(0.9),
                      )
                    : Icon(
                        Icons.copy_outlined,
                        size: 16,
                        color: txtColor.withOpacity(0.7),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Versión extendida del badge con información adicional
class WorkerCodeBadgeExtended extends StatelessWidget {
  final String code;
  final String label;
  final IconData? icon;
  final Color? color;

  const WorkerCodeBadgeExtended({
    Key? key,
    required this.code,
    this.label = 'CÓDIGO',
    this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono personalizable
          Icon(
            icon ?? Icons.qr_code,
            size: 18,
            color: themeColor,
          ),
          const SizedBox(width: 8),

          // Información del código
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Etiqueta
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: themeColor.withOpacity(0.8),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),

              // Código con formato
              Text(
                code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                  fontFamily: 'Monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget animado para mostrar un código con efecto de "escaneo"
class AnimatedWorkerCodeBadge extends StatefulWidget {
  final String code;
  final Color color;

  const AnimatedWorkerCodeBadge({
    Key? key,
    required this.code,
    required this.color,
  }) : super(key: key);

  @override
  State<AnimatedWorkerCodeBadge> createState() =>
      _AnimatedWorkerCodeBadgeState();
}

class _AnimatedWorkerCodeBadgeState extends State<AnimatedWorkerCodeBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1 * _animation.value),
                blurRadius: 8 * _animation.value,
                spreadRadius: 1 * _animation.value,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.6),
                    widget.color,
                    widget.color.withOpacity(0.6),
                  ],
                  stops: [
                    0,
                    _animation.value,
                    1,
                  ],
                ).createShader(bounds),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),

              // Código con formato especial
              Text(
                widget.code,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: widget.color.withOpacity(0.6),
                      blurRadius: 4 * _animation.value,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
