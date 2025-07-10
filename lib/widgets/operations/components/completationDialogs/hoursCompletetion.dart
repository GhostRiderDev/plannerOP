import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';

class HoursCompletetion extends StatefulWidget {
  final WorkerGroup group;
  final Function onStateChanged;

  HoursCompletetion({required this.group, required this.onStateChanged});

  @override
  _HoursDialogState createState() => _HoursDialogState();
}

class _HoursDialogState extends State<HoursCompletetion> {
  bool _isProcessing = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final ID_UNIT_JORNAL = int.parse(dotenv.get('ID_UNIT_JORNAL', fallback: '1'));
  final ID_UNIT_HOURS = int.parse(dotenv.get('ID_UNIT_HOURS', fallback: '2'));

  // Controladores para todos los tipos de horas
  final TextEditingController _hodController = TextEditingController();
  final TextEditingController _honController = TextEditingController();
  final TextEditingController _hedController = TextEditingController();
  final TextEditingController _henController = TextEditingController();
  final TextEditingController _hodfController = TextEditingController();
  final TextEditingController _honfController = TextEditingController();
  final TextEditingController _hedfController = TextEditingController();
  final TextEditingController _henfController = TextEditingController();
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

  //  MÉTODO PARA DETERMINAR QUÉ CAMPOS MOSTRAR SEGÚN LA UNIDAD DE MEDIDA
  Map<String, bool> get _getVisibleFields {
    if (widget.group.idUnitOfMeasure == ID_UNIT_JORNAL) {
      // Jornada - Solo horas extras y festivas
      return {
        'ordinarias': false, // Deshabilitar HOD, HON
        'extras': true, // Mostrar HED, HEN
        // No mostrar  HODF, HONF
        'festivas': true, // Mostrar HEDF, HENF
        'festivasOrdinarias': false, // Deshabilitar HODF, HONF
      };
    } else if (widget.group.idUnitOfMeasure == ID_UNIT_HOURS) {
      return {
        'ordinarias': true, // Deshabilitar HOD, HON
        'extras': true, // Mostrar HED, HEN
        // No mostrar  HODF, HONF
        'festivas': true, // Mostrar HEDF, HENF
        'festivasOrdinarias': true, // Deshabilitar HODF, HONF
      };
    } else if (widget.group.idUnitOfMeasure == 4) {
      // Horas - Mostrar todo
      return {
        'ordinarias': true, // Mostrar HOD, HON
        'extras': true, // Mostrar HED, HEN
        'festivas': true, // Mostrar todas las festivas
      };
    } else {
      // Otras unidades - Mostrar todo por defecto
      return {
        'ordinarias': true,
        'extras': true,
        'festivas': true,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.access_time, color: Color(0xFF3182CE)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Completar Jornada",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //  DESCRIPCIÓN CONTEXTUAL
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Color(0xFF4299E1)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Registro laboral",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A5568),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
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
                      'Completar',
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
    final visibleFields = _getVisibleFields;

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

        //  HORAS ORDINARIAS - Condicional
        if (visibleFields['ordinarias']!) ...[
          _buildHoursCategorySection('Horas Ordinarias', Color(0xFF3182CE), [
            _buildHourField('HOD', 'Horas Ordinarias Diurnas', _hodController,
                (value) => _hod = value),
            _buildHourField('HON', 'Horas Ordinarias Nocturnas', _honController,
                (value) => _hon = value),
          ]),
          SizedBox(height: 12),
        ],

        //  HORAS EXTRAS - Condicional
        if (visibleFields['extras']!) ...[
          _buildHoursCategorySection('Horas Extras', Color(0xFFD69E2E), [
            _buildHourField('HED', 'Horas Extras Diurnas', _hedController,
                (value) => _hed = value),
            _buildHourField('HEN', 'Horas Extras Nocturnas', _henController,
                (value) => _hen = value),
          ]),
          SizedBox(height: 12),
        ],

        //  HORAS FESTIVAS - Condicional
        if (visibleFields['festivas']!) ...[
          _buildHoursCategorySection('Horas Festivas', Color(0xFF9F7AEA), [
            //  CONDICIONAL: Solo mostrar HODF, HONF si está habilitado
            if (visibleFields['festivasOrdinarias']!) ...[
              _buildHourField('HODF', 'Horas Ordinarias Diurnas Festivas',
                  _hodfController, (value) => _hodf = value),
              _buildHourField('HONF', 'Horas Ordinarias Nocturnas Festivas',
                  _honfController, (value) => _honf = value),
            ],
            //  SIEMPRE mostrar HEDF, HENF cuando festivas esté habilitado
            _buildHourField('HEDF', 'Horas Extras Diurnas Festivas',
                _hedfController, (value) => _hedf = value),
            _buildHourField('HENF', 'Horas Extras Nocturnas Festivas',
                _henfController, (value) => _henf = value),
          ]),
          SizedBox(height: 12),
        ],

        //  MENSAJE CUANDO NO HAY HORAS ORDINARIAS
        if (!visibleFields['ordinarias']!) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFFFE69C)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFD69E2E)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Para jornada laboral, las horas ordinarias (HOD/HON) están incluidas en el salario base.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B5A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],

        // Resumen total
        _buildHoursSummary(),
      ],
    );
  }

  //  RESUMEN ACTUALIZADO CON LÓGICA CONDICIONAL
  Widget _buildHoursSummary() {
    final visibleFields = _getVisibleFields;

    double totalHours = 0.0;
    if (visibleFields['ordinarias']!) {
      totalHours += _hod + _hon;
    }
    if (visibleFields['extras']!) {
      totalHours += _hed + _hen;
    }
    if (visibleFields['festivas']!) {
      totalHours += _hodf + _honf + _hedf + _henf;
    }

    if (totalHours > 0) {
      return Container(
        margin: EdgeInsets.only(top: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF86EFAC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            //  DESGLOSE PARA JORNADA LABORAL
            if (!visibleFields['ordinarias']!) ...[
              SizedBox(height: 8),
              Text(
                'Nota: Las horas ordinarias (8h) están incluidas en el salario base de la jornada.',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF059669),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  //  RESTO DE MÉTODOS IGUALES...
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

  Future<void> _handleCompletion() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      //  DATOS CONDICIONALES SEGÚN UNIDAD DE MEDIDA
      final visibleFields = _getVisibleFields;
      final jornalData = <String, dynamic>{
        'observations': _observationsController.text.trim(),
        'unitOfMeasure': widget.group.idUnitOfMeasure,
        'endDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'endTime': _formattedTime,
      };

      // Solo incluir los campos visibles
      if (visibleFields['ordinarias']!) {
        jornalData['hod'] = _hod;
        jornalData['hon'] = _hon;
      }
      if (visibleFields['extras']!) {
        jornalData['hed'] = _hed;
        jornalData['hen'] = _hen;
      }
      if (visibleFields['festivas']!) {
        if (visibleFields['festivasOrdinarias']!) {
          jornalData['hodf'] = _hodf;
          jornalData['honf'] = _honf;
        }
        jornalData['hedf'] = _hedf;
        jornalData['henf'] = _henf;
      }

      // TODO: Implementar llamada al API
      await Future.delayed(Duration(seconds: 1));

      // NOTIFICAR COMPLETACIÓN SIN CERRAR CONTEXTO AQUÍ
      widget.onStateChanged();
      // EL CIERRE LO MANEJA EL CALLBACK

      final totalHours = (visibleFields['ordinarias']! ? _hod + _hon : 0) +
          (visibleFields['extras']! ? _hed + _hen : 0) +
          (visibleFields['festivas']! ? _hodf + _honf + _hedf + _henf : 0);

      if (mounted) {
        showSuccessToast(
          context,
          'Jornada completada: Total ${totalHours.toStringAsFixed(2)} horas registradas',
        );
      }
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
