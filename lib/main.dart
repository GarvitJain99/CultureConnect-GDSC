import 'package:cultureconnect/pages/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  try {
    await dotenv.load(fileName: ".env"); 
    print("✅ .env file loaded successfully!");
  } catch (e) {
    print("❌ Error loading .env file: $e"); // Check logs for details
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CultureConnect',
      home: SplashScreen(),
    );
  }
}