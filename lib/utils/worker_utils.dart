import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

Color getColorForWorker(Worker worker) {
  final List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];
  final int index = worker.id % colors.length;
  return colors[index];
}
