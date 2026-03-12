import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'firebase_options.dart';
import 'package:ku_wongnai/pages/main_page.dart';
import 'package:ku_wongnai/pages/welcome_page.dart';
import 'package:ku_wongnai/pages/signin_page.dart';
import 'package:ku_wongnai/pages/register_page.dart';
import 'package:ku_wongnai/service/seed_page.dart';

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