import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/hooks/loaders/loader.dart';
import 'package:plannerop/providers/areas.dart';
import 'package:plannerop/providers/auth.dart';
import 'package:plannerop/providers/chargersOp.dart';
import 'package:plannerop/providers/clients.dart';
import 'package:plannerop/providers/faults.dart';
import 'package:plannerop/providers/feedings.dart';
import 'package:plannerop/providers/incapacities.dart';
import 'package:plannerop/providers/operations.dart';
import 'package:plannerop/providers/programmings.dart';
import 'package:plannerop/providers/task.dart';
import 'package:plannerop/providers/user.dart';
import 'package:plannerop/providers/workerGroup.dart';
import 'pages/login.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/providers/workers.dart';
import 'package:flutter_animated_splash/flutter_animated_splash.dart';

Future<void> main() async {
  // Asegúrate de inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final hashKey = dotenv.get('HASH_KEY', fallback: 'default_hash_key');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OperationsProvider()),
        ChangeNotifierProvider(create: (_) => WorkersProvider()),
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

        /// NO BORRAR ESTE CODIGO!!!!
        /// Impide que se quede informacion basura entre sesiones
        ChangeNotifierProxyProvider6<
            OperationsProvider,
            WorkersProvider,
            AreasProvider,
            UserProvider,
            ClientsProvider,
            FeedingProvider,
            AuthProvider>(
          create: (context) => AuthProvider(
            operationsProvider: context.read<OperationsProvider>(),
            workersProvider: context.read<WorkersProvider>(),
            areasProvider: context.read<AreasProvider>(),
            clientsProvider: context.read<ClientsProvider>(),
            feedingProvider: context.read<FeedingProvider>(),
            faultsProvider: context.read<FaultsProvider>(),
            tasksProvider: context.read<TasksProvider>(),
            userProvider: context.read<UserProvider>(),
            chargersOpProvider: context.read<ChargersOpProvider>(),
            programmingsProvider: context.read<ProgrammingsProvider>(),
          ),
          update: (context, op, w, a, u, c, f, auth) =>
              auth ??
              AuthProvider(
                operationsProvider: op,
                workersProvider: w,
                areasProvider: a,
                userProvider: u,
                clientsProvider: c,
                feedingProvider: f,
                faultsProvider: context.read<FaultsProvider>(),
                tasksProvider: context.read<TasksProvider>(),
                chargersOpProvider: context.read<ChargersOpProvider>(),
                programmingsProvider: context.read<ProgrammingsProvider>(),
              ),
        ),
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
      loadDataAfterAuthentication(context, isMounted: () => mounted);
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
