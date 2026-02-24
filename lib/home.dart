import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูล User (ถ้ามี)
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page (Test Mode)"),
        backgroundColor: const Color(0xFFF2C85B),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              "Engine ทำงานปกติแล้ว!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "ถ้าคุณเห็นหน้านี้ แปลว่าโครงสร้างแอปถูกต้อง",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Text(
              "Login as: ${user?.email ?? 'Guest User'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // พากลับไปหน้า Welcome เพื่อเช็คปุ่ม Log In / Sign Up
                Navigator.pushNamed(context, '/welcome');
              },
              child: const Text("ไปหน้า Welcome"),
            ),
          ],
        ),
      ),
    );
  }
}