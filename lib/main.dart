import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/grid_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]).then((_) {
    runApp(const CalculosoreApp());
  });
}

class CalculosoreApp extends StatelessWidget {
  const CalculosoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculosore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Navy Blue
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF10B981), // Mint/Emerald
          surface: Colors.white,
        ),
        // Style global pour une vibe "Smooth"
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const GridScreen(),
    );
  }
}
