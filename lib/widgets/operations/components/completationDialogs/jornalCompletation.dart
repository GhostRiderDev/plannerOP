import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';

class JornalCompletionDialog extends StatefulWidget {
  final WorkerGroup group;
  final Function onStateChanged;

  JornalCompletionDialog({required this.group, required this.onStateChanged});

  @override
  _JornalCompletionDialogState createState() => _JornalCompletionDialogState();
}

class _JornalCompletionDialogState extends State<JornalCompletionDialog> {
  bool _isProcessing = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Controladores para todos los tipos de horas
  final TextEditingController _hodController =
      TextEditingController(); // Horas Ordinarias Diurnas
  final TextEditingController _honController =
      TextEditingController(); // Horas Ordinarias Nocturnas
  final TextEditingController _hedController =
      TextEditingController(); // Horas Extras Diurnas
  final TextEditingController _henController =
      TextEditingController(); // Horas Extras Nocturnas
  final TextEditingController _hodfController =
      TextEditingController(); // Horas Ordinarias Diurnas Festivas
  final TextEditingController _honfController =
      TextEditingController(); // Horas Ordinarias Nocturnas Festivas
  final TextEditingController _hedfController =
      TextEditingController(); // Horas Extras Diurnas Festivas
  final TextEditingController _henfController =
      TextEditingController(); // Horas Extras Nocturnas Festivas
  final TextEditingController _observationsController = TextEditingController();

  // Calculados
  late String _formattedTime;

  // Valores numéricos
  double _hod = 0.0;
  double _hon = 0.0;
  double _hed = 0.0;
  double _hen = 0.0;
  double _hodf = 0.0;
  double _honf = 0.0;
  double _hedf = 0.0;
  double _henf = 0.0;

  @override
  void initState() {
    super.initState();
    _formattedTime =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.access_time, color: Color(0xFF3182CE)),
          SizedBox(width: 8),
          Text('Completar Jornada'),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHoursSection(),
              SizedBox(height: 16),
              _buildObservationsSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor:
                _isProcessing ? Color(0xFFCBD5E0) : Color(0xFF718096),
          ),
          child: Text('Cancelar'),
        ),
        NeumorphicButton(
          style: NeumorphicStyle(
            depth: _isProcessing ? 0 : 2,
            intensity: 0.7,
            color: _isProcessing ? Color(0xFF9AE6B4) : Color(0xFF3182CE),
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
          ),
          onPressed: _isProcessing ? null : _handleCompletion,
          child: SizedBox(
            width: 120,
            height: 36,
            child: Center(
              child: _isProcessing
                  ? AppLoader(
                      color: Colors.white,
                      size: LoaderSize.medium,
                      message: 'Procesando...')
                  : Text(
                      'Completar Jornada',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Color(0xFFD69E2E)),
            SizedBox(width: 6),
            Text(
              'Registro de Horas Laborales',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // ✅ Horas Ordinarias
        _buildHoursCategorySection('Horas Ordinarias', Color(0xFF3182CE), [
          _buildHourField('HOD', 'Horas Ordinarias Diurnas', _hodController,
              (value) => _hod = value),
          _buildHourField('HON', 'Horas Ordinarias Nocturnas', _honController,
              (value) => _hon = value),
        ]),

        SizedBox(height: 12),

        // ✅ Horas Extras
        _buildHoursCategorySection('Horas Extras', Color(0xFFD69E2E), [
          _buildHourField('HED', 'Horas Extras Diurnas', _hedController,
              (value) => _hed = value),
          _buildHourField('HEN', 'Horas Extras Nocturnas', _henController,
              (value) => _hen = value),
        ]),

        SizedBox(height: 12),

        // ✅ Horas Festivas
        _buildHoursCategorySection('Horas Festivas', Color(0xFF9F7AEA), [
          _buildHourField('HODF', 'Horas Ordinarias Diurnas Festivas',
              _hodfController, (value) => _hodf = value),
          _buildHourField('HONF', 'Horas Ordinarias Nocturnas Festivas',
              _honfController, (value) => _honf = value),
          _buildHourField('HEDF', 'Horas Extras Diurnas Festivas',
              _hedfController, (value) => _hedf = value),
          _buildHourField('HENF', 'Horas Extras Nocturnas Festivas',
              _henfController, (value) => _henf = value),
        ]),

        // ✅ Resumen total
        _buildHoursSummary(),
      ],
    );
  }

  /// ✅ Widget para categoría de horas
  Widget _buildHoursCategorySection(
      String title, Color color, List<Widget> fields) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          ...fields
              .map((field) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: field,
                  ))
              .toList(),
        ],
      ),
    );
  }

  /// ✅ Campo individual para horas
  Widget _buildHourField(String code, String label,
      TextEditingController controller, Function(double) onChanged) {
    return Row(
      children: [
        Container(
          width: 50,
          child: Text(
            code,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        SizedBox(width: 8),
        Container(
          width: 80,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
            style: TextStyle(fontSize: 12),
            onChanged: (value) {
              setState(() {
                onChanged(double.tryParse(value) ?? 0.0);
              });
            },
          ),
        ),
      ],
    );
  }

  /// ✅ Resumen de horas totales
  Widget _buildHoursSummary() {
    double totalHours =
        _hod + _hon + _hed + _hen + _hodf + _honf + _hedf + _henf;

    if (totalHours > 0) {
      return Container(
        margin: EdgeInsets.only(top: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF86EFAC)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Total de horas registradas: ${totalHours.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  /// Sección de observaciones
  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observaciones (opcional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _observationsController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Comentarios adicionales sobre la jornada...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: EdgeInsets.all(10),
          ),
        ),
      ],
    );
  }

  /// Manejar la finalización de la jornada
  Future<void> _handleCompletion() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      //  Datos específicos de jornada laboral con todos los tipos de horas
      final jornalData = {
        'hod': _hod, // Horas Ordinarias Diurnas
        'hon': _hon, // Horas Ordinarias Nocturnas
        'hed': _hed, // Horas Extras Diurnas
        'hen': _hen, // Horas Extras Nocturnas
        'hodf': _hodf, // Horas Ordinarias Diurnas Festivas
        'honf': _honf, // Horas Ordinarias Nocturnas Festivas
        'hedf': _hedf, // Horas Extras Diurnas Festivas
        'henf': _henf, // Horas Extras Nocturnas Festivas
        'observations': _observationsController.text.trim(),
        'unitOfMeasure': widget.group.idUnitOfMeasure,
        'endDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'endTime': _formattedTime,
      };

      debugPrint('✅ Datos de jornada laboral: $jornalData');

      // TODO: Implementar llamada al API
      // final success = await widget.provider.completeJornalGroup(
      //   widget.assignment,
      //   widget.workers,
      //   widget.groupId,
      //   jornalData,
      //   context,
      // );

      // Simular éxito por ahora
      await Future.delayed(Duration(seconds: 1));

      widget.onStateChanged();
      Navigator.of(context).pop();

      showSuccessToast(
        context,
        'Jornada completada: Total ${(_hod + _hon + _hed + _hen + _hodf + _honf + _hedf + _henf).toStringAsFixed(2)} horas registradas',
      );
    } catch (e) {
      debugPrint('Error al completar jornada: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        showErrorToast(context, 'Error al completar la jornada: $e');
      }
    }
  }

  @override
  void dispose() {
    _hodController.dispose();
    _honController.dispose();
    _hedController.dispose();
    _henController.dispose();
    _hodfController.dispose();
    _honfController.dispose();
    _hedfController.dispose();
    _henfController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
}
