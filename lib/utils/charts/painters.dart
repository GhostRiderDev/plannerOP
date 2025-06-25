import 'package:flutter/material.dart';
import 'dart:math' as math;
import './chartData.dart';

class DonutChartPainter extends CustomPainter {
  final List<ChartData> data;
  final int selectedIndex;
  final double innerRadiusRatio;

  DonutChartPainter(
    this.data,
    this.selectedIndex, {
    this.innerRadiusRatio = 0.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double donutWidth = radius * (1 - innerRadiusRatio);
    final double outerRadius = radius;
    final double innerRadius = radius - donutWidth;

    double totalValue = 0;
    for (var item in data) {
      totalValue += item.value;
    }

    if (totalValue == 0) return;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final isSelected = i == selectedIndex;

      double sweepAngle = 2 * math.pi * (item.value / totalValue);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isSelected ? item.color : item.color.withOpacity(0.7);

      // Sombra si está seleccionado
      if (isSelected) {
        canvas.drawShadow(
          _createDonutPath(
              center, outerRadius, innerRadius, startAngle, sweepAngle),
          Colors.black.withOpacity(0.3),
          4,
          true,
        );
      }

      // Dibujar arco exterior
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Dibujar arco interior (para crear el efecto donut)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = Colors.white,
      );

      startAngle += sweepAngle;
    }
  }

  Path _createDonutPath(Offset center, double outerRadius, double innerRadius,
      double startAngle, double sweepAngle) {
    return Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class PieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final int selectedIndex;

  PieChartPainter(this.data, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;

    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final isSelected = selectedIndex == i;

      final sweepAngle = (item.value / total) * 2 * math.pi;
      final sectionRadius = isSelected ? radius * 1.1 : radius;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + sectionRadius * math.cos(startAngle),
          center.dy + sectionRadius * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: sectionRadius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      final paint = Paint()
        ..color = isSelected ? item.color : item.color.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      if (isSelected) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawPath(path, borderPaint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<ChartData> data;
  final int selectedIndex;
  final bool isHorizontal;
  final double maxValue;
  final bool showLabels;
  final bool showValues;

  BarChartPainter(
    this.data,
    this.selectedIndex, {
    this.isHorizontal = true,
    required this.maxValue,
    this.showLabels = true,
    this.showValues = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    final barPadding = 12.0;
    final marginLeft = 8.0;
    final marginRight = 8.0;
    final chartWidth = size.width - marginLeft - marginRight;
    final barHeight =
        (size.height - (data.length + 1) * barPadding) / data.length;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final isSelected = i == selectedIndex;

      final barWidth = (item.value / maxValue) * chartWidth;
      final y = i * (barHeight + barPadding) + barPadding;

      // Calcular el centro vertical de la barra
      final barCenterY = y + (barHeight / 2);

      // Barra de fondo
      final backgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(marginLeft, y, chartWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        backgroundRect,
        Paint()..color = Colors.grey.shade200,
      );

      // Barra principal
      if (barWidth > 0) {
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(marginLeft, y, barWidth, barHeight),
          const Radius.circular(4),
        );

        final paint = Paint()
          ..color = isSelected ? item.color : item.color.withOpacity(0.8)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(barRect, paint);

        // Sombra si está seleccionado
        if (isSelected) {
          canvas.drawShadow(
            Path()..addRRect(barRect),
            Colors.black.withOpacity(0.3),
            4,
            true,
          );

          // Borde si está seleccionado
          final borderPaint = Paint()
            ..color = item.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawRRect(barRect, borderPaint);
        }

        // Dibujar etiqueta del buque DENTRO de la barra (lado izquierdo)
        if (showLabels) {
          final labelTextPainter = TextPainter(
            text: TextSpan(
              text: _truncateText(item.name, 20),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          labelTextPainter.layout();

          // Centrar verticalmente y posicionar a la izquierda dentro de la barra
          final labelX = marginLeft + 8;
          final labelY = barCenterY - (labelTextPainter.height / 2);

          // Solo dibujar si la barra es lo suficientemente ancha
          if (barWidth > labelTextPainter.width + 16) {
            labelTextPainter.paint(canvas, Offset(labelX, labelY));
          }
        }

        // Dibujar valor DENTRO de la barra (lado derecho)
        if (showValues) {
          final valueTextPainter = TextPainter(
            text: TextSpan(
              text: '${item.value}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          valueTextPainter.layout();

          // Centrar verticalmente y posicionar a la derecha dentro de la barra
          final valueX = marginLeft + barWidth - valueTextPainter.width - 8;
          final valueY = barCenterY - (valueTextPainter.height / 2);

          // Estrategia de posicionamiento según el ancho de la barra
          if (barWidth > 80) {
            // Barra ancha: valor dentro, a la derecha
            valueTextPainter.paint(canvas, Offset(valueX, valueY));
          } else if (barWidth > 40) {
            // Barra mediana: valor centrado
            final valueXCentered =
                marginLeft + (barWidth / 2) - (valueTextPainter.width / 2);
            valueTextPainter.paint(canvas, Offset(valueXCentered, valueY));
          } else {
            // Barra pequeña: valor fuera de la barra
            final valueXOutside = marginLeft + barWidth + 8;
            if (valueXOutside + valueTextPainter.width <
                size.width - marginRight) {
              // Cambiar color para texto fuera de la barra
              final valueTextPainterOutside = TextPainter(
                text: TextSpan(
                  text: '${item.value}',
                  style: TextStyle(
                    color: isSelected ? item.color : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                textDirection: TextDirection.ltr,
              );
              valueTextPainterOutside.layout();
              final valueYOutside =
                  barCenterY - (valueTextPainterOutside.height / 2);
              valueTextPainterOutside.paint(
                  canvas, Offset(valueXOutside, valueYOutside));
            }
          }
        }
      }

      // Si la barra es muy pequeña, mostrar el label fuera
      if (showLabels && barWidth <= 60) {
        final labelTextPainter = TextPainter(
          text: TextSpan(
            text: _truncateText(item.name, 15),
            style: TextStyle(
              color: isSelected ? item.color : Colors.grey[700],
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        labelTextPainter.layout();

        // Posicionar a la izquierda de la barra
        final labelX = marginLeft - labelTextPainter.width - 8;
        final labelY = barCenterY - (labelTextPainter.height / 2);

        if (labelX >= 0) {
          labelTextPainter.paint(canvas, Offset(labelX, labelY));
        }
      }
    }

    // Dibujar líneas de referencia verticales
    _drawGridLines(canvas, size, marginLeft, chartWidth);
  }

  void _drawGridLines(
      Canvas canvas, Size size, double marginLeft, double chartWidth) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Líneas verticales de referencia (cada 25% del valor máximo)
    for (int i = 1; i <= 4; i++) {
      final x = marginLeft + (chartWidth * i / 4);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<ChartData> data;
  final int selectedIndex;
  final double maxValue;

  LineChartPainter(
    this.data,
    this.selectedIndex, {
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pointRadius = 4.0;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (item.value / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Dibujar punto
      final pointPaint = Paint()
        ..color = i == selectedIndex ? item.color : item.color.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        i == selectedIndex ? pointRadius * 1.5 : pointRadius,
        pointPaint,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter personalizado para el gráfico de líneas horario (sin interacción)
class HourlyLineChartPainter extends CustomPainter {
  final List<HourlyDistributionData> data;
  final int selectedIndex;
  final double maxValue;

  HourlyLineChartPainter(this.data, this.selectedIndex,
      {required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFF3182CE)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const margin = 40.0;
    final chartWidth = size.width - (margin * 2);
    final chartHeight = size.height - (margin * 2);

    // Dibujar líneas de referencia horizontales
    for (int i = 0; i <= 4; i++) {
      final y = margin + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        gridPaint,
      );

      // Etiquetas del eje Y
      final value = (maxValue * (4 - i) / 4).round();
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toString(),
          style: const TextStyle(
            color: Color(0xFF718096),
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(margin - textPainter.width - 8, y - textPainter.height / 2));
    }

    if (data.length <= 1) return;

    // Crear el path de la línea
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = margin + (chartWidth * i / (data.length - 1));
      final y = margin + chartHeight - (chartHeight * data[i].value / maxValue);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Dibujar la línea principal
    canvas.drawPath(path, paint);

    // Dibujar puntos y líneas indicadoras
    for (int i = 0; i < data.length; i++) {
      final point = points[i];
      final item = data[i];
      final isSelected = i == selectedIndex;

      // Punto del gráfico
      final pointPaint = Paint()
        ..color = isSelected ? item.color : item.color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, isSelected ? 8.0 : 6.0, pointPaint);

      // Borde del punto
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(point, isSelected ? 8.0 : 6.0, borderPaint);

      // Línea vertical indicadora hasta el eje X
      final linePaint = Paint()
        ..color = item.color.withOpacity(0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        point,
        Offset(point.dx, margin + chartHeight),
        linePaint,
      );

      // Valor sobre el punto si está seleccionado
      if (isSelected) {
        final valueTextPainter = TextPainter(
          text: TextSpan(
            text: '${item.value}',
            style: TextStyle(
              color: item.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valueTextPainter.layout();

        final valueX = point.dx - valueTextPainter.width / 2;
        final valueY = point.dy - valueTextPainter.height - 12;

        // Fondo del texto
        final backgroundRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            valueX - 4,
            valueY - 2,
            valueTextPainter.width + 8,
            valueTextPainter.height + 4,
          ),
          const Radius.circular(4),
        );

        canvas.drawRRect(
          backgroundRect,
          Paint()..color = Colors.white.withOpacity(0.9),
        );

        canvas.drawRRect(
          backgroundRect,
          Paint()
            ..color = item.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );

        valueTextPainter.paint(canvas, Offset(valueX, valueY));
      }

      // Etiquetas del eje X (cada 2 elementos para evitar sobreposición)
      if (i % 2 == 0 || data.length <= 8) {
        final hourText = item.hour.split('-')[0]; // Solo la hora inicial
        final labelTextPainter = TextPainter(
          text: TextSpan(
            text: hourText,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelTextPainter.layout();

        final labelX = point.dx - labelTextPainter.width / 2;
        final labelY = margin + chartHeight + 8;

        labelTextPainter.paint(canvas, Offset(labelX, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
