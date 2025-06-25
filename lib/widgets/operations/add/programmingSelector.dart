import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:plannerop/widgets/operations/components/workers/selectorModal.dart';
import 'package:provider/provider.dart';

class ProgrammingSelector extends StatefulWidget {
  final String? startDate;
  final Function(Programming) onProgrammingSelected;
  final Programming? initialValue;

  const ProgrammingSelector({
    Key? key,
    required this.startDate,
    required this.onProgrammingSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  State<ProgrammingSelector> createState() => _ProgrammingSelectorState();
}

class _ProgrammingSelectorState extends State<ProgrammingSelector> {
  List<Programming> _filteredProgrammings = [];
  List<Programming> _selectableProgrammings = [];
  List<Programming> _nonSelectableProgrammings = [];
  bool _isLoading = false;
  Programming? _selectedProgramming;

  @override
  void initState() {
    super.initState();
    _selectedProgramming = widget.initialValue;
  }

  @override
  void didUpdateWidget(ProgrammingSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _filterProgrammingsByStatus() {
    final programmingProvider =
        Provider.of<ProgrammingsProvider>(context, listen: false);
    final allProgrammings = programmingProvider.programmings;

    _selectableProgrammings =
        allProgrammings.where((p) => p.status == 'UNASSIGNED').toList();

    _nonSelectableProgrammings = allProgrammings
        .where((p) => p.status == 'ASSIGNED' || p.status == 'COMPLETED')
        .toList();

    // Ordenar para que COMPLETED aparezca después de ASSIGNED
    _nonSelectableProgrammings.sort((a, b) {
      if (a.status == 'ASSIGNED' && b.status == 'COMPLETED') return -1;
      if (a.status == 'COMPLETED' && b.status == 'ASSIGNED') return 1;
      return 0;
    });

    _filteredProgrammings = [
      ..._selectableProgrammings,
      ..._nonSelectableProgrammings
    ];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'UNASSIGNED':
        return Colors.green;
      case 'ASSIGNED':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'UNASSIGNED':
        return 'Disponible';
      case 'ASSIGNED':
        return 'Asignado';
      case 'COMPLETED':
        return 'Completado';
      default:
        return 'Desconocido';
    }
  }

  void _openProgrammingSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgrammingSelectionModal(
        startDate: widget.startDate!,
        programmings: _filteredProgrammings,
        selectableProgrammings: _selectableProgrammings,
        nonSelectableProgrammings: _nonSelectableProgrammings,
        selectedProgramming: _selectedProgramming,
        isLoading: _isLoading,
        onProgrammingSelected: (programming) {
          // Solo permitir selección si es UNASSIGNED
          if (programming.status == 'UNASSIGNED') {
            setState(() {
              _selectedProgramming = programming;
            });
            widget.onProgrammingSelected(programming);
            Navigator.pop(context);
          }
        },
        onRefresh: () {
          // _loadProgrammings();
        },
        getStatusColor: _getStatusColor,
        getStatusText: _getStatusText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _filterProgrammingsByStatus();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con contador
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Row(
            children: [
              const Icon(
                Icons.event_note,
                size: 14,
                color: Color(0xFF4A5568),
              ),
              const SizedBox(width: 4),
              const Text(
                'Programación del Cliente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(width: 8),
              // Contador de disponibles
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectableProgrammings.length} disponibles',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              if (_nonSelectableProgrammings.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_nonSelectableProgrammings.length} no disponibles',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (_isLoading)
                AppLoader(
                  size: LoaderSize.medium,
                  color: Colors.blue,
                )
            ],
          ),
        ),

        // Selector
        GestureDetector(
          onTap: _openProgrammingSelector,
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.3,
              color: Colors.white,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono o indicador
                _buildLeadingIcon(),
                const SizedBox(width: 12),

                // Contenido principal
                Expanded(
                  child: _isLoading
                      ? _buildLoadingContent()
                      : _selectedProgramming != null
                          ? _buildSelectedContent()
                          : _buildEmptyContent(),
                ),

                // Flecha
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadingIcon() {
    if (_isLoading) {
      return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: AppLoader(
              size: LoaderSize.small,
              color: Colors.blue,
            ),
          ));
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _selectedProgramming != null
            ? _getStatusColor(_selectedProgramming!.status).withOpacity(0.1)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.event_note,
        color: _selectedProgramming != null
            ? _getStatusColor(_selectedProgramming!.status)
            : const Color(0xFF3182CE),
        size: 18,
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Text(
      'Cargando programaciones...',
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF718096),
      ),
    );
  }

  Widget _buildSelectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedProgramming!.service,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(_selectedProgramming!.status)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(_selectedProgramming!.status)
                      .withOpacity(0.3),
                ),
              ),
              child: Text(
                _getStatusText(_selectedProgramming!.status),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(_selectedProgramming!.status),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 12,
              color: Color(0xFF718096),
            ),
            const SizedBox(width: 4),
            Text(
              _selectedProgramming!.timeStart,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.location_on_outlined,
              size: 12,
              color: Color(0xFF718096),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _selectedProgramming!.ubication,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    final hasNoSelectableProgrammings =
        _selectableProgrammings.isEmpty && !_isLoading;

    return Text(
      hasNoSelectableProgrammings
          ? 'No hay programaciones disponibles para asignar'
          : 'Seleccionar programación del cliente',
      style: TextStyle(
        fontSize: 14,
        color: const Color(0xFF718096),
        fontStyle:
            hasNoSelectableProgrammings ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}
