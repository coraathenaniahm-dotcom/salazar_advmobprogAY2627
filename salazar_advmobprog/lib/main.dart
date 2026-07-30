import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Starts the app
void main() {
  runApp(
    // Gives the theme to the app
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ),
  );
}

// Main app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Gets the theme
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      // App title
      title: 'Simple App State',

      // Light mode
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // Dark mode
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // Changes the theme
      themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,

      // Opens this screen first
      home: const CounterPage(),
    );
  }
}

// Saves the theme
class ThemeModel extends ChangeNotifier {
  // Starts with light mode
  bool _isDark = false;

  // Gets the theme
  bool get isDark => _isDark;

  // Changes the theme
  void toggleTheme() {
    _isDark = !_isDark;

    // Updates the app
    notifyListeners();
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

            // Shows a small window
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  // Gets the theme
                  final themeModel =
                      Provider.of<ThemeModel>(context, listen: false);

                  // Small window
                  return AlertDialog(
                    // Window title
                    title: const Text('Theme settings'),

                    // Window content
                    content: StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          // Puts the text and switch apart
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Switch name
                            const Text('Dark mode'),

                            // Theme switch
                            Switch(
                              // Current theme
                              value: themeModel.isDark,

                              // Changes the theme
                              onChanged: (value) {
                                themeModel.toggleTheme();

                                // Updates the window
                                setState(() {});
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    // Close button
                    actions: [
                      TextButton(
                        // Closes the window
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
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