import 'package:flutter/material.dart';
import 'package:ku_wongnai/pages/signin_page.dart';
import 'package:ku_wongnai/pages/register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2C85B),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50), // ปรับระยะห่างจากขอบล่างเล็กน้อย
              child: Column(
                children: [
                  // --- ปุ่ม Log In ---
                  SizedBox(
                    width: 220, // ขยายจาก 190 เป็น 220
                    height: 50, // ขยายจาก 44 เป็น 50
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF1C9),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16, // ปรับตัวอักษรให้ใหญ่ขึ้น
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInPage()),
                        );
                      },
                      child: const Text('Log In'),
                    ),
                  ),

                  const SizedBox(height: 15), // เพิ่มช่องว่างระหว่างปุ่มเล็กน้อย

                  // --- ปุ่ม Sign Up ---
                  SizedBox(
                    width: 220, // ขยายจาก 190 เป็น 220
                    height: 50, // ขยายจาก 44 เป็น 50
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF1C9),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16, // ปรับตัวอักษรให้ใหญ่ขึ้น
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}