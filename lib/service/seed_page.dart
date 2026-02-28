import 'package:flutter/material.dart';
import 'seed_restaurants.dart';

class SeedPage extends StatelessWidget {
  const SeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Restaurants'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Upload Restaurants to Firebase'),
          onPressed: () async {
            try {
              await seedRestaurants();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Seed ข้อมูลเข้า Firebase สำเร็จ')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
    );
  }
}