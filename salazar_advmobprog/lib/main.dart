import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:salazar_advmobprog/screens/setting_screen.dart';
import 'package:salazar_advmobprog/screens/home_screen.dart';
import 'package:salazar_advmobprog/screens/login_screen.dart';
import 'package:salazar_advmobprog/screens/profile_screen.dart';
import 'package:salazar_advmobprog/screens/splash_screen.dart';
import 'package:salazar_advmobprog/screens/signup_screen.dart';
import 'package:salazar_advmobprog/providers/theme_provider.dart';
import 'package:salazar_advmobprog/models/user.dart';
import 'package:salazar_advmobprog/firebase_options.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load(fileName: 'assets/.env');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Print uncaught Flutter errors during development
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };

      runApp(const MyApp());
    },
    (Object error, StackTrace stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(540, 720),
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const _AppShell(),
        );
      },
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Simple App State',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3D5A9B),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D4A9E),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF211A2B),
          surfaceContainer: const Color(0xFF2A2038),
          surfaceContainerHighest: const Color(0xFF352646),
          onSurface: const Color(0xFFF5EEFF),
          onSurfaceVariant: const Color(0xFFD8CDE5),
        ),
        scaffoldBackgroundColor: const Color(0xFF211A2B),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),

      themeMode:
          themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

      routes: {
        '/settings': (context) => const SettingsScreen(),

        '/login': (context) => const LoginScreen(),

        '/signup': (context) => const SignupScreen(),

        '/home': (context) {
          final arguments =
              ModalRoute.of(context)?.settings.arguments;

          final userId = arguments is User
              ? arguments.id
              : arguments is Map<String, dynamic>
                  ? arguments['id'] as int?
                  : null;

          return HomeScreen(
            userId: userId ?? 1,
          );
        },

        '/profile': (context) => const ProfileScreen(),
      },

      home: const SplashScreen(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open theme settings',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/settings',
              );
            },
          ),
        ],
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
            ),

            Text(
              '$_counter',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Add one',
        child: const Icon(Icons.add),
      ),
    );
  }
}