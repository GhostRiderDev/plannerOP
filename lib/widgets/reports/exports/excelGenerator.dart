import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plannerop/widgets/reports/exports/WorkerReportRow.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class ExcelGenerator {
  static Future<File> generateReport(ReportData reportData) async {
    final xlsio.Workbook workbook = xlsio.Workbook();

    // Crear hojas
    final workerSheet = workbook.worksheets[0];
    workerSheet.name = 'Reporte-Trabajadores';

    final generalSheet = workbook.worksheets.add();
    generalSheet.name = 'Reporte-General';

    // Crear estilos
    final styles = _createStyles(workbook);

    // Generar hoja de trabajadores
    await _generateWorkerSheet(workerSheet, reportData, styles);

    // Generar hoja general
    await _generateGeneralSheet(generalSheet, reportData, styles);

    // Guardar archivo
    final output = await getTemporaryDirectory();
    final fileName =
        'reporte_detallado_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${output.path}/$fileName';

    final List<int> bytes = workbook.saveAsStream();
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    workbook.dispose();
    return file;
  }

  static Map<String, xlsio.Style> _createStyles(xlsio.Workbook workbook) {
    final titleStyle = workbook.styles.add('titleStyle');
    titleStyle.bold = true;
    titleStyle.fontSize = 14;
    titleStyle.fontColor = '#2D3748';

    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#2D3748';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.hAlign = xlsio.HAlignType.center;

    final summaryHeaderStyle = workbook.styles.add('summaryHeaderStyle');
    summaryHeaderStyle.bold = true;
    summaryHeaderStyle.fontSize = 12;
    summaryHeaderStyle.backColor = '#E2E8F0';

    final evenRowStyle = workbook.styles.add('evenRowStyle');
    evenRowStyle.backColor = '#F7FAFC';

    final oddRowStyle = workbook.styles.add('oddRowStyle');
    oddRowStyle.backColor = '#EDF2F7';

    return {
      'title': titleStyle,
      'header': headerStyle,
      'summaryHeader': summaryHeaderStyle,
      'evenRow': evenRowStyle,
      'oddRow': oddRowStyle,
    };
  }

// Agregar este método a la clase ExcelGenerator
  static Future<File> generateReportAtPath(
      ReportData reportData, String filePath) async {
    final xlsio.Workbook workbook = xlsio.Workbook();

    // Crear hojas
    final workerSheet = workbook.worksheets[0];
    workerSheet.name = 'Reporte-Trabajadores';

    final generalSheet = workbook.worksheets.add();
    generalSheet.name = 'Reporte-General';

    // Crear estilos
    final styles = _createStyles(workbook);

    // Generar hoja de trabajadores
    await _generateWorkerSheet(workerSheet, reportData, styles);

    // Generar hoja general
    await _generateGeneralSheet(generalSheet, reportData, styles);

    // Guardar archivo en la ruta específica
    final List<int> bytes = workbook.saveAsStream();
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    workbook.dispose();
    return file;
  }

  static Future<void> _generateWorkerSheet(
    xlsio.Worksheet sheet,
    ReportData reportData,
    Map<String, xlsio.Style> styles,
  ) async {
    int rowIndex = 1;

    // Título
    sheet
        .getRangeByName('A$rowIndex')
        .setText('${reportData.reportTitle} - Detalle por Trabajadores');
    sheet.getRangeByName('A$rowIndex').cellStyle = styles['title']!;
    sheet.getRangeByName('A$rowIndex:O$rowIndex').merge();
    rowIndex++;

    // Información del reporte
    rowIndex++;
    sheet.getRangeByName('A$rowIndex').setText('Fecha de generación:');
    sheet
        .getRangeByName('B$rowIndex')
        .setText(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()));
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Período:');
    sheet.getRangeByName('B$rowIndex').setText(reportData.dateRange);
    rowIndex++;

    // Estadísticas
    rowIndex++;
    sheet.getRangeByName('A$rowIndex').setText('ESTADÍSTICAS');
    sheet.getRangeByName('A$rowIndex').cellStyle = styles['summaryHeader']!;
    sheet.getRangeByName('A$rowIndex:C$rowIndex').merge();
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Total operaciones:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.statistics['total']!.toDouble());
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Total trabajadores:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.statistics['totalWorkers']!.toDouble());
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Registros de trabajadores:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.workerRows.length.toDouble());
    rowIndex++;

    // Encabezados
    rowIndex += 2;
    final workerHeaders = [
      'ID Operación',
      'Estado',
      'Área',
      'Cliente',
      'Supervisores',
      'Fecha Inicio',
      'Hora Inicio',
      'Fecha Fin',
      'Hora Fin',
      'Horas Trabajadas',
      'Embarcación',
      'Tarea',
      'Turno',
      'DNI Trabajador',
      'Nombre Trabajador'
    ];

    for (int i = 0; i < workerHeaders.length; i++) {
      sheet.getRangeByIndex(rowIndex, i + 1).setText(workerHeaders[i]);
      sheet.getRangeByIndex(rowIndex, i + 1).cellStyle = styles['header']!;
    }
    rowIndex++;

    // Datos
    for (int i = 0; i < reportData.workerRows.length; i++) {
      final row = reportData.workerRows[i];
      final rowStyle = i % 2 == 0 ? styles['evenRow']! : styles['oddRow']!;

      final values = [
        row.operationId.toString(),
        row.status,
        row.area,
        row.client,
        row.supervisors,
        row.startDate,
        row.startTime,
        row.endDate,
        row.endTime,
        row.workedHours,
        row.vessel,
        row.task,
        row.shift,
        row.workerDni,
        row.workerName,
      ];

      for (int j = 0; j < values.length; j++) {
        sheet.getRangeByIndex(rowIndex, j + 1).setText(values[j]);
        sheet.getRangeByIndex(rowIndex, j + 1).cellStyle = rowStyle;
      }
      rowIndex++;
    }

    // Ajustar anchos de columna
    _setColumnWidths(sheet,
        [60, 80, 100, 80, 150, 90, 70, 90, 70, 100, 100, 100, 70, 100, 150]);
  }

  static Future<void> _generateGeneralSheet(
    xlsio.Worksheet sheet,
    ReportData reportData,
    Map<String, xlsio.Style> styles,
  ) async {
    int rowIndex = 1;

    // Título
    sheet
        .getRangeByName('A$rowIndex')
        .setText('${reportData.reportTitle} - Resumen General');
    sheet.getRangeByName('A$rowIndex').cellStyle = styles['title']!;
    sheet.getRangeByName('A$rowIndex:N$rowIndex').merge();
    rowIndex++;

    // Información del reporte
    rowIndex++;
    sheet.getRangeByName('A$rowIndex').setText('Fecha de generación:');
    sheet
        .getRangeByName('B$rowIndex')
        .setText(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()));
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Período:');
    sheet.getRangeByName('B$rowIndex').setText(reportData.dateRange);
    rowIndex++;

    // Estadísticas
    rowIndex++;
    sheet.getRangeByName('A$rowIndex').setText('ESTADÍSTICAS');
    sheet.getRangeByName('A$rowIndex').cellStyle = styles['summaryHeader']!;
    sheet.getRangeByName('A$rowIndex:C$rowIndex').merge();
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Total operaciones:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.statistics['total']!.toDouble());
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Completadas:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.statistics['completed']!.toDouble());
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('En curso:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.statistics['inProgress']!.toDouble());
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Pendientes:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.statistics['pending']!.toDouble());
    rowIndex++;

    sheet.getRangeByName('A$rowIndex').setText('Canceladas:');
    sheet
        .getRangeByName('B$rowIndex')
        .setNumber(reportData.statistics['canceled']!.toDouble());
    rowIndex++;

    // Encabezados
    rowIndex += 2;
    final generalHeaders = [
      'ID Operación',
      'Estado',
      'Área',
      'Cliente',
      'Supervisores',
      'Fecha Inicio',
      'Hora Inicio',
      'Fecha Fin',
      'Hora Fin',
      'Horas Trabajadas',
      'Embarcación',
      'Tarea',
      'Total Trabajadores',
      'Turnos'
    ];

    for (int i = 0; i < generalHeaders.length; i++) {
      sheet.getRangeByIndex(rowIndex, i + 1).setText(generalHeaders[i]);
      sheet.getRangeByIndex(rowIndex, i + 1).cellStyle = styles['header']!;
    }
    rowIndex++;

    // Datos
    for (int i = 0; i < reportData.generalRows.length; i++) {
      final row = reportData.generalRows[i];
      final rowStyle = i % 2 == 0 ? styles['evenRow']! : styles['oddRow']!;

      final values = [
        row.operationId.toString(),
        row.status,
        row.area,
        row.client,
        row.supervisors,
        row.startDate,
        row.startTime,
        row.endDate,
        row.endTime,
        row.workedHours,
        row.vessel,
        row.task,
        row.totalWorkers.toString(),
        row.totalShifts.toString(),
      ];

      for (int j = 0; j < values.length; j++) {
        sheet.getRangeByIndex(rowIndex, j + 1).setText(values[j]);
        sheet.getRangeByIndex(rowIndex, j + 1).cellStyle = rowStyle;
      }
      rowIndex++;
    }

    // Ajustar anchos de columna
    _setColumnWidths(
        sheet, [60, 80, 100, 80, 150, 90, 70, 90, 70, 100, 100, 100, 120, 60]);
  }

  static void _setColumnWidths(xlsio.Worksheet sheet, List<int> widths) {
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidthInPixels(i + 1, widths[i]);
    }
  }
}
