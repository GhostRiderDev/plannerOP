import 'package:flutter/material.dart';

class WorkerEmptyState extends StatelessWidget {
  final String searchQuery;

  const WorkerEmptyState({
    Key? key,
    required this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //icon
          Icon(
            searchQuery.isEmpty ? Icons.people : Icons.search,
            size: 64,
            color: const Color(0xFF4299E1),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? '¡No hay trabajadores registrados!'
                : '¡No se encontraron trabajadores!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4299E1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Agrega trabajadores usando el botón +'
                : 'Intenta con otra búsqueda',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
