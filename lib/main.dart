import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cropmate/screens/splash_screen.dart';
import 'package:cropmate/screens/home.dart';
import 'package:cropmate/screens/plant_identification_page.dart';
import 'package:cropmate/screens/disease_detection_page.dart';
import 'package:cropmate/screens/plants_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Enable high refresh rate (120Hz) support
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark, // For iOS
        statusBarIconBrightness: Brightness.dark, // For Android
        // For Android - changed to light for better visibility on colored backgrounds
        systemNavigationBarColor: Color.fromARGB(255, 255, 255, 255),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('Error during app initialization: $e');
  }

  runApp(const PlantricApp());
}

class PlantricApp extends StatelessWidget {
  const PlantricApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ecoyield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        primaryColor: Colors.green,
        brightness: Brightness.light,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
      home: const SplashScreen(), // Changed from HomePage to SplashScreen
      routes: {
        '/home': (context) => const HomePage(),
        '/disease-detection': (context) => const DiseaseDetectionPage(),
        '/plant-identification': (context) => const PlantIdentificationPage(),
        '/plants': (context) => const PlantsPage(),
      },
    );
  }
}
