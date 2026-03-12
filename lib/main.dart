import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'firebase_options.dart';
import 'welcome.dart';
import 'signin.dart';
import 'register.dart';
import 'service/seed_page.dart';
import 'main_page.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const accessToken = String.fromEnvironment('ACCESS_TOKEN');
  MapboxOptions.setAccessToken(accessToken);
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
      initialRoute: '/welcome', 
      routes: {
        '/home': (context) => const MainPage(), 
        '/welcome': (context) => const WelcomePage(),
        '/signin': (context) => const SignInPage(),
        '/register': (context) => const RegisterPage(),
        '/seed': (context) => const SeedPage(),
      },
    );
  }
}