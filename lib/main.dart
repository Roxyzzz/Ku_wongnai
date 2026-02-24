import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'welcome.dart';
import 'signin.dart';
import 'register.dart';

void main() async {
  // 1. ตรวจสอบการเชื่อมต่อกับระบบพื้นฐานของ Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. เริ่มต้นระบบ Firebase (ถ้าไฟล์นี้ Error ให้รัน flutterfire configure ใน terminal)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KU Wongnai',
      initialRoute: '/home', 
      routes: {
        '/home': (context) => const HomePage(),
        '/welcome': (context) => const WelcomePage(),
        '/signin': (context) => const SignInPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}