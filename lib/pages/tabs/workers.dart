import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:plannerop/widgets/workers/tab/workersContent.dart';
import 'package:plannerop/widgets/workers/tab/workersHeader.dart';
import 'package:plannerop/widgets/workers/workerFilter.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/widgets/workers/workerAddDialog.dart';
import 'package:plannerop/widgets/workers/workerDetailDialog.dart';
import 'package:plannerop/core/model/fault.dart';

class WorkersTab extends StatefulWidget {
  const WorkersTab({Key? key}) : super(key: key);

  @override
  State<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<WorkersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  WorkerFilter _currentFilter = WorkerFilter.all;
  FaultType? _selectedFaultType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF4299E1),
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header y búsqueda
              WorkersHeader(
                searchController: _searchController,
                searchQuery: _searchQuery,
              ),

              // Stats y lista todo en uno
              Expanded(
                child: WorkersContent(
                  searchQuery: _searchQuery,
                  currentFilter: _currentFilter,
                  selectedFaultType: _selectedFaultType,
                  onFilterChanged: (filter) {
                    setState(() {
                      _currentFilter = filter;
                      if (filter != WorkerFilter.faults) {
                        _selectedFaultType = null;
                      }
                    });
                  },
                  onFaultTypeChanged: (type) {
                    setState(() => _selectedFaultType = type);
                  },
                  onAddWorker: _addWorker,
                  onUpdateWorker: _updateWorker,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: NeumorphicFloatingActionButton(
          style: NeumorphicStyle(
            color: const Color(0xFF4299E1),
            shape: NeumorphicShape.flat,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(28)),
            depth: 8,
            intensity: 0.65,
            lightSource: LightSource.topLeft,
          ),
          child: const Icon(Icons.person_add, color: Colors.white),
          onPressed: () => WorkerAddDialog.show(context, _addWorker),
        ));
  }

  void _addWorker(Worker workerData) {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoader(
        color: Colors.white,
        size: LoaderSize.small,
      ),
    );

    workersProvider.addWorker(workerData, context).then((result) {
      Navigator.of(context).pop();
      if (result['success']) {
        showSuccessToast(context, result['message']);
      } else {
        showErrorToast(context, result['message']);
      }
    });
  }

  void _updateWorker(Worker oldWorker, Worker newWorker) {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);
    workersProvider.updateWorker(oldWorker, newWorker, context);
  }
}
