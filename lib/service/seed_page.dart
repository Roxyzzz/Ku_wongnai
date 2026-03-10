import 'package:flutter/material.dart';
import './seed_restaurants.dart'; 

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});

  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  bool _isLoading = false;

  // ฟังก์ชันหลักสำหรับส่งข้อมูลขึ้น Firebase
  Future<void> _handleUpload() async {
    setState(() => _isLoading = true);

    try {
      // เรียกฟังก์ชันจากไฟล์ seed_restaurants.dart
      await seedRestaurants();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ อัปโหลดข้อมูลร้านอาหารสำเร็จ!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Database'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'กดปุ่มเพื่ออัปเดตข้อมูลจากไฟล์ Seed\nไปยัง Cloud Firestore',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            // ปุ่มอัปโหลดที่ปรับปรุงแล้ว
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleUpload,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              icon: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.send),
              label: Text(
                _isLoading ? 'กำลังประมวลผล...' : 'อัปโหลด Seed ไปยัง Firebase',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 20),
            if (!_isLoading)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('กลับหน้าหลัก', style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }
}