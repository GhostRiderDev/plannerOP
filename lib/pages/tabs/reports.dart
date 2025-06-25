import 'package:flutter/material.dart';
import 'package:plannerop/store/reports.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:plannerop/widgets/reports/components/charFactory.dart';
import 'package:plannerop/widgets/reports/components/charSelector.dart';
import 'package:plannerop/widgets/reports/constants.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/widgets/reports/reportFilter.dart';
import 'package:plannerop/widgets/reports/exports/exportOptions.dart';
import 'package:plannerop/widgets/reports/exports/reportDataTable.dart';
import 'package:plannerop/widgets/reports/components/activeFiltersDisplay.dart';
import 'package:plannerop/utils/toast.dart';

class ReportesTab extends StatelessWidget {
  const ReportesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportsProvider(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadFilterData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(reportsProvider),
          body: SafeArea(
            child: Column(
              children: [
                if (reportsProvider.isFiltering)
                  _buildFilterSection(reportsProvider),
                if (reportsProvider.isExporting)
                  _buildExportSection(reportsProvider),
                if (!reportsProvider.isFiltering &&
                    !reportsProvider.isExporting)
                  _buildActiveFilters(reportsProvider),
                if (reportsProvider.showCharts &&
                    !reportsProvider.isFiltering &&
                    !reportsProvider.isExporting)
                  _buildChartSelector(reportsProvider),
                Expanded(child: _buildMainContent(reportsProvider)),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(reportsProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ReportsProvider provider) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: const Color(0xFF4299E1),
      centerTitle: false,
      title: const Text(
        'Reportes de Operaciones',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(
            provider.showCharts ? Icons.table_chart : Icons.bar_chart,
            color: Colors.white,
          ),
          onPressed: provider.toggleView,
          tooltip: provider.showCharts ? 'Ver tabla de datos' : 'Ver gráficos',
        ),
        IconButton(
          icon: Icon(
            provider.isFiltering ? Icons.filter_list_off : Icons.filter_list,
            color: Colors.white,
          ),
          onPressed: provider.toggleFilterPanel,
          tooltip: 'Filtros',
        ),
        if (provider.isLoadingFilterData)
          AppLoader(
            size: LoaderSize.small,
            color: Colors.white,
          )
      ],
    );
  }

  Widget _buildFilterSection(ReportsProvider provider) {
    return ReportFilter(
      periods: const [],
      areas: provider.areas,
      zones: provider.zones,
      motorships: provider.motorships,
      statuses: provider.statuses,
      selectedPeriod: provider.selectedPeriod,
      selectedArea: provider.selectedArea,
      selectedZone: provider.selectedZone,
      selectedMotorship: provider.selectedMotorship,
      selectedStatus: provider.selectedStatus,
      startDate: provider.startDate,
      endDate: provider.endDate,
      onApply: provider.applyFilter,
      isChartsView: provider.showCharts,
    );
  }

  Widget _buildExportSection(ReportsProvider provider) {
    return ExportOptions(
      periodName: provider.selectedPeriod,
      startDate: provider.startDate,
      endDate: provider.endDate,
      area: provider.selectedArea,
      zone: provider.selectedZone,
      motorship: provider.selectedMotorship,
      status: provider.selectedStatus,
      onExport: (format) {
        showInfoToast(context, "Exportando reporte en formato $format");
        provider.toggleExportPanel();
      },
    );
  }

  Widget _buildActiveFilters(ReportsProvider provider) {
    return ActiveFiltersDisplay(
      startDate: provider.startDate,
      endDate: provider.endDate,
      selectedArea: provider.selectedArea,
      selectedZone: provider.selectedZone,
      selectedMotorship: provider.selectedMotorship,
      selectedStatus: provider.selectedStatus,
      onChangeFilters: provider.toggleFilterPanel,
    );
  }

  Widget _buildChartSelector(ReportsProvider provider) {
    return ChartSelector(
      selectedChart: provider.selectedChart,
      onChartChanged: provider.setSelectedChart,
      chartOptions: ChartConstants.chartOptions,
    );
  }

  Widget _buildMainContent(ReportsProvider provider) {
    if (provider.showCharts) {
      return ChartFactory.createChart(
        chartType: provider.selectedChart,
        startDate: provider.startDate,
        endDate: provider.endDate,
        area: provider.selectedArea,
        zone: provider.selectedZone,
        motorship: provider.selectedMotorship,
        status: provider.selectedStatus,
      );
    } else {
      return ReportDataTable(
        periodName: provider.selectedPeriod,
        startDate: provider.startDate,
        endDate: provider.endDate,
        area: provider.selectedArea,
        zone: provider.selectedZone,
        motorship: provider.selectedMotorship,
        status: provider.selectedStatus,
      );
    }
  }

  Widget? _buildFloatingActionButton(ReportsProvider provider) {
    if (!provider.showCharts) {
      return FloatingActionButton.extended(
        onPressed: provider.toggleExportPanel,
        backgroundColor: const Color(0xFF4299E1),
        icon: const Icon(Icons.file_download),
        label: const Text('Exportar'),
        foregroundColor: Colors.white,
      );
    }
    return null;
  }
}
