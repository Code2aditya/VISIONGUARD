import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/glass_theme.dart';
import 'screens/vehicle_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VisionGuardApp());
}

class VisionGuardApp extends StatelessWidget {
  const VisionGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionGuard Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GlassTheme.backgroundColor,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: GlassTheme.primaryCyan,
          secondary: GlassTheme.accentPurple,
          surface: GlassTheme.glassSurface,
        ),
        useMaterial3: true,
      ),
      home: const VehicleSelectionScreen(),
    );
  }
}
