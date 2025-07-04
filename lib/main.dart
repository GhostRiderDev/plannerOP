import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/store/incapacities.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workerGroup.dart';
import 'pages/login.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/workers.dart';
import 'package:flutter_animated_splash/flutter_animated_splash.dart';
import 'package:plannerop/utils/dataManager.dart';

Future<void> main() async {
  // Asegúrate de inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OperationsProvider()),
        ChangeNotifierProvider(create: (_) => WorkersProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AreasProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => FaultsProvider()),
        ChangeNotifierProvider(create: (_) => ChargersOpProvider()),
        ChangeNotifierProvider(create: (_) => WorkerGroupsProvider()),
        ChangeNotifierProvider(create: (_) => FeedingProvider()),
        ChangeNotifierProvider(create: (_) => ProgrammingsProvider()),
        ChangeNotifierProvider(create: (_) => IncapacityProvider()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();

    // Inicializar el DataManager después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataManager().loadDataAfterAuthentication(context);
    });
  }

  // Creamos un GlobalKey para obtener el contexto incluso antes de mostrar la pantalla principal
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Planeador de Operaciones',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AnimatedSplash(
        type: Transition.size,
        curve: Curves.easeInOut,
        backgroundColor: Colors.blue,
        navigator: const LoginPage(),
        durationInSeconds: 2,
        child: Image.asset(
          "assets/splash.png",
          width: 200,
          height: 200,
        ),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
