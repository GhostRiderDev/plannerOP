import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/store/operations.dart';
import 'package:provider/provider.dart';

Widget buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildInChargerItem(User charger) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade400,
            radius: 18,
            child: Text(
              charger.name.toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        charger.name.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                if (charger.cargo.isNotEmpty)
                  Text(
                    charger.cargo.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF718096),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper para obtener el icono adecuado según el tipo de comida
IconData getIconForFoodType(String foodType, bool isMarked) {
  switch (foodType) {
    case 'Desayuno':
      return isMarked ? Icons.free_breakfast : Icons.free_breakfast_outlined;
    case 'Almuerzo':
      return isMarked ? Icons.restaurant : Icons.restaurant_outlined;
    case 'Cena':
      return isMarked ? Icons.dinner_dining : Icons.dinner_dining_outlined;
    case 'Media noche':
      return isMarked ? Icons.nightlight_round : Icons.nightlight_outlined;
    default:
      return isMarked ? Icons.restaurant : Icons.restaurant_outlined;
  }
}

Widget buildFilterBar(
  List<String> areas,
  List<User> supervisors,
  bool _showFilters,
  String? _selectedArea,
  int? _selectedSupervisorId,
  BuildContext context,
  Function setState, {
  Function(String?)? onAreaChanged,
  Function(int?)? onSupervisorChanged,
  Function()? onClearFilters,
  Function()? onToggleFilters, // AGREGAR ESTE PARÁMETRO
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Text(
              'Filtros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Spacer(),
            NeumorphicButton(
              style: NeumorphicStyle(
                depth: 2,
                intensity: 0.7,
                boxShape: NeumorphicBoxShape.circle(),
                color: _showFilters
                    ? const Color(0xFF3182CE)
                    : const Color(0xFFE2E8F0),
              ),
              padding: const EdgeInsets.all(8),
              onPressed: onToggleFilters, // USAR EL CALLBACK
              child: Icon(
                Icons.filter_list,
                size: 18,
                color: _showFilters ? Colors.white : const Color(0xFF718096),
              ),
            ),
          ],
        ),
        if (_showFilters) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Área',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _selectedArea,
                  hint: Text('Todas las áreas'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las áreas'),
                    ),
                    ...areas.map((area) => DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        )),
                  ],
                  onChanged: (value) {
                    if (onAreaChanged != null) {
                      onAreaChanged(value);
                    }
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Supervisor',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _selectedSupervisorId,
                  hint: Text('Todos los supervisores'),
                  isExpanded: true,
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Todos los supervisores',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...supervisors.map<Widget>((User supervisor) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          constraints: BoxConstraints(minWidth: 100),
                          child: Text(
                            supervisor.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: Color(0xFF2D3748),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ];
                  },
                  menuMaxHeight: 300,
                  itemHeight: 60,
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFEDF2F7),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text('Todos los supervisores'),
                      ),
                    ),
                    ...supervisors.map((supervisor) => DropdownMenuItem<int>(
                          value: supervisor.id,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFEDF2F7),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(supervisor.name),
                          ),
                        )),
                  ],
                  onChanged: (value) {
                    if (onSupervisorChanged != null) {
                      onSupervisorChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          if (_selectedArea != null || _selectedSupervisorId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.7,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  if (onClearFilters != null) {
                    onClearFilters();
                  }
                },
                child: Text(
                  'Limpiar filtros',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    ),
  );
}
