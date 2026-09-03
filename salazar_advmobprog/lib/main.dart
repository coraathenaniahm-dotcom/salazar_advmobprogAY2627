import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:salazar_advmobprog/screens/setting_screen.dart';
import 'package:salazar_advmobprog/screens/home_screen.dart';
import 'package:salazar_advmobprog/screens/login_screen.dart';
import 'package:salazar_advmobprog/screens/profile_screen.dart';
import 'package:salazar_advmobprog/screens/splash_screen.dart';
import 'package:salazar_advmobprog/providers/theme_provider.dart';
import 'package:salazar_advmobprog/models/user.dart';

// Starts the app
void main() {
  // Catch any errors that Flutter doesn't catch
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(
    () {
      runApp(
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
          child: const MyApp(),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    },
  );
}

// Main app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(540, 720),
      builder: (context, child) {
        return MaterialApp(
          // App title
          title: 'Simple App State',

          // Light mode
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            fontFamily: 'Poppins',
          ),

          // Dark mode
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Poppins',
          ),

          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          routes: {
            '/settings': (context) => const SettingsScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) {
              final arguments = ModalRoute.of(context)?.settings.arguments;
              final userId = arguments is User
                  ? arguments.id
                  : arguments is Map<String, dynamic>
                  ? arguments['id'] as int?
                  : null;
              return HomeScreen(userId: userId ?? 1);
            },
            '/profile': (context) => const ProfileScreen(),
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}

// Counter screen
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  // Counter value
  int _counter = 0;

  // Adds 1
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar
      appBar: AppBar(
        title: const Text('Counter Screen'),
        actions: [
          IconButton(
            // Opens settings
            icon: const Icon(Icons.settings),

            // Button text
            tooltip: 'Open theme settings',

            // Navigate to settings page
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),

      // Screen content
      body: Center(
        child: Column(
          // Puts everything in the center
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Message
            const Text('You have pushed the button this many times:'),

            // Shows the number
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            // Adds space
            const SizedBox(height: 24),
          ],
        ),
      ),

      // Add button
      floatingActionButton: FloatingActionButton(
        // Adds 1
        onPressed: _incrementCounter,

        // Button text
        tooltip: 'Add one',

        // Plus icon
        child: const Icon(Icons.add),
      ),
    );
  }
}
