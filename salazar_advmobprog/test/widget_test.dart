import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salazar_advmobprog/main.dart';
import 'package:salazar_advmobprog/providers/theme_provider.dart';
import 'package:salazar_advmobprog/screens/login_screen.dart';

void main() {
  testWidgets('app starts on the splash screen and redirects', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    expect(find.text('NUBD Exchange'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 1600));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}