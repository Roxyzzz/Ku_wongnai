import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import './seed_restaurants.dart';

// 1x1 transparent PNG placeholder (68 bytes)
final Uint8List _placeholderPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
  0xAE, 0x42, 0x60, 0x82,
]);

// รายชื่อ folder ของทุกร้านใน Firebase Storage
const List<String> _restaurantFolders = [
  'restaurants/artofcoffee/cover.jpg',
  'restaurants/bagbagbrewcoffee/cover.jpg',
  'restaurants/inthanincoffeeku/cover.jpg',
  'restaurants/truecoffeeku/cover.jpg',
  'restaurants/yogurutoชั้น1อาคารวิศวกรรมสิ่งแวดล้อม/cover.jpg',
  'restaurants/beleafjuiceshop/cover.jpg',
  'restaurants/cafeamazonสาขาอาคารพันธุ์ไม้/cover.jpg',
  'restaurants/chamaชามะชาไข่มุกระเบิด/cover.jpg',
  'restaurants/siskucoffee/cover.jpg',
  'restaurants/starbucksตรงข้ามคณะบริหารฯ/cover.jpg',
  'restaurants/เนสกาแฟสตรีทคาเฟ่/cover.jpg',
  'restaurants/maxbeefyakinikux/cover.jpg',
  'restaurants/ม่าม่าพร/cover.jpg',
  'restaurants/ศูนย์อาหารคณะวิทยาศาสตร์/cover.jpg',
  'restaurants/ศูนย์อาหารคณะวิศวกรรมศาสตร์/cover.jpg',
  'restaurants/ศูนย์อาหารคณะเกษตร/cover.jpg',
  'restaurants/โรงอาหารกลาง1บาร์ใหม่/cover.jpg',
  'restaurants/โรงอาหารกลาง2บาร์ใหม่กว่า/cover.jpg',
  'restaurants/โรงอาหารคณะบริหารธุรกิจ/cover.jpg',
  'restaurants/โรงอาหารคณะวนศาสตร์/cover.jpg',
  'restaurants/โรงอาหารคณะสถาปัตยกรรมศาสตร์/cover.jpg',
  'restaurants/โรงอาหารคณะสัตวแพทยศาสตร์/cover.jpg',
];

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});

  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  bool _isLoading = false;
  bool _isExporting = false;
  bool _isUpdating = false;
  bool _isCreatingFolders = false;

  Future<void> _handleUpload() async {
    setState(() => _isLoading = true);
    try {
      await seedRestaurants();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สำเร็จ!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผิดพลาด: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreateFolders() async {
    setState(() => _isCreatingFolders = true);
    int success = 0;
    int skip = 0;
    try {
      for (final path in _restaurantFolders) {
        final ref = FirebaseStorage.instance.ref(path);
        try {
          // ตรวจสอบว่ามีไฟล์อยู่แล้วไหม (ถ้ามีจะ skip)
          await ref.getMetadata();
          skip++;
        } catch (_) {
          // ไม่มีไฟล์ → อัปโหลด placeholder
          await ref.putData(
            _placeholderPng,
            SettableMetadata(contentType: 'image/png', customMetadata: {'placeholder': 'true'}),
          );
          success++;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้าง folder สำเร็จ $success ร้าน (ข้าม $skip ที่มีอยู่แล้ว)'),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผิดพลาด: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isCreatingFolders = false);
    }
  }

  /// อัปเดตเฉพาะ foodTypes ใน Firebase document ที่มีอยู่แล้ว
  Future<void> _handleUpdateFoodTypes() async {
    setState(() => _isUpdating = true);
    try {
      final col = FirebaseFirestore.instance.collection('restaurants');
      // map ชื่อ foodTypes ตาม docId จาก seed_restaurants.dart
      final snapshot = await col.get();
      int updated = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // ถ้ายังไม่มี foodTypes ให้ skip (หรือมีก็ update ใหม่)
        final existingFoodTypes = data['foodTypes'];
        if (existingFoodTypes != null && (existingFoodTypes as List).isNotEmpty) continue;

        // ดึง category แล้วกำหนด foodTypes default
        final category = data['category'] ?? '';
        List<String> foodTypes;
        if (category == 'food') {
          foodTypes = ['ข้าวราดแกง', 'อาหารตามสั่ง', 'ก๋วยเตี๋ยว'];
        } else if (category == 'cafe') {
          foodTypes = ['กาแฟ', 'ชา', 'เครื่องดื่ม'];
        } else {
          foodTypes = ['กาแฟ', 'เครื่องดื่ม'];
        }

        await doc.reference.update({'foodTypes': foodTypes});
        updated++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปเดต foodTypes สำเร็จ! ($updated ร้าน)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ผิดพลาด: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .get();

      // ignore: avoid_print
      print('===== FIREBASE EXPORT: ${snapshot.docs.length} docs =====');

      for (final doc in snapshot.docs) {
        final d = doc.data();
        // ignore: avoid_print
        print('--- DOC_ID: ${doc.id} ---');
        d.forEach((key, value) {
          // ignore: avoid_print
          print('  $key: $value');
        });
        // ignore: avoid_print
        print('');
      }

      // ignore: avoid_print
      print('===== END OF EXPORT =====');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export สำเร็จ! ${snapshot.docs.length} ร้าน — ดูใน Debug Console ของ VS Code'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export ผิดพลาด: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isLoading ? 'กำลังประมวลผล...' : 'อัปโหลด Seed ไปยัง Firebase',
                style: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isExporting ? null : _handleExport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isExporting ? 'กำลัง Export...' : 'Export ข้อมูลจาก Firebase → Console',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isUpdating ? null : _handleUpdateFoodTypes,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.local_offer),
              label: Text(
                _isUpdating ? 'กำลังอัปเดต...' : 'อัปเดต foodTypes → Firebase',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isCreatingFolders ? null : _handleCreateFolders,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              icon: _isCreatingFolders
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.create_new_folder),
              label: Text(
                _isCreatingFolders ? 'กำลังสร้าง folder...' : 'สร้าง Folder ทุกร้านใน Storage',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),
            if (!_isLoading && !_isExporting && !_isUpdating && !_isCreatingFolders)
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