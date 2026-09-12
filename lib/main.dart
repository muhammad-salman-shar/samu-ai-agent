import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NovaAgentApp());
}

class NovaAgentApp extends StatelessWidget {
  const NovaAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add providers here if needed
      ],
      child: MaterialApp(
        title: 'NovaAgent Local',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF08080A),
          primaryColor: const Color(0xFF00F5A0),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00F5A0),
            secondary: Color(0xFF00D2FF),
            surface: Color(0xFF131318),
            background: Color(0xFF08080A),
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF131318),
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF00F5A0)),
            titleTextStyle: TextStyle(
              color: Color(0xFF00F5A0),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5A0),
              foregroundColor: const Color(0xFF08080A),
              elevation: 0,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF08080A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
