import 'package:flutter/material.dart';
import 'seed_restaurants.dart';           // มี seedRestaurants()
import 'updateseed_restaurants.dart'; // มี updateRestaurantLocations()

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});

  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  bool isLoading = false;

  Future<void> _handleSeed() async {
    setState(() => isLoading = true);

    try {
      // 1️⃣ สร้างร้าน
      await seedRestaurants();

      // 2️⃣ เติมพิกัด
      await updateRestaurantLocations();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Seed + Update Location สำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Restaurants'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_upload),
          label: Text(isLoading
              ? 'กำลังอัปโหลด...'
              : 'Upload Restaurants to Firebase'),
          onPressed: isLoading ? null : _handleSeed,
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
    );
  }
}