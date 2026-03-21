import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'package:ku_wongnai/widgets/restaurant_detail_sheet.dart';

class NearbyRestaurantsPage extends StatefulWidget {
  const NearbyRestaurantsPage({super.key});

  @override
  State<NearbyRestaurantsPage> createState() => _NearbyRestaurantsPageState();
}

class _NearbyRestaurantsPageState extends State<NearbyRestaurantsPage> {
  bool isLoading = true;
  String locationNote = '';
  geo.Position? currentPosition;
  String selectedFoodType = 'all';
  String _userRole = 'user';

  static const List<String> _allFoodTypes = [
    'ก๋วยเตี๋ยว', 'ข้าวราดแกง', 'อาหารตามสั่ง', 'ส้มตำ', 'ยำ',
    'เนื้อย่าง', 'ปิ้งย่าง', 'ผัดไทย', 'อาหารญี่ปุ่น',
    'กาแฟ', 'ชา', 'เบเกอรี่', 'ชาไข่มุก', 'น้ำผลไม้',
    'สมูทตี้', 'โยเกิร์ต', 'เครื่องดื่ม',
  ];

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() => _userRole = (doc.data()?['role'] ?? 'user').toString());
      }
    } catch (_) {}
  }

  // ตำแหน่งกลาง KU สำหรับ fallback (กรณี emulator หรือ location ไม่ได้)
  static const double _kuLat = 13.8476;
  static const double _kuLng = 100.5693;

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // fallback ใช้ตำแหน่ง KU
        _useFallback('Location Service ปิดอยู่ — แสดงร้านบริเวณ มก. แทน');
        return;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        _useFallback('ไม่ได้รับสิทธิ์ตำแหน่ง — แสดงร้านบริเวณ มก. แทน');
        return;
      }

      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('timeout');
        },
      );
      if (!mounted) return;
      setState(() { currentPosition = pos; isLoading = false; locationNote = ''; });
    } catch (e) {
      // emulator หรือ location ช้า → fallback KU
      _useFallback('ไม่พบตำแหน่ง — แสดงร้านบริเวณ มก. แทน');
    }
  }

  void _useFallback(String note) {
    if (!mounted) return;
    setState(() {
      currentPosition = geo.Position(
        latitude: _kuLat,
        longitude: _kuLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      locationNote = note;
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD54F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ร้านใกล้ฉัน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ========== foodType Chip Filter ==========
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('ทั้งหมด'),
                          selected: selectedFoodType == 'all',
                          onSelected: (_) => setState(() => selectedFoodType = 'all'),
                          selectedColor: Colors.orange,
                          labelStyle: TextStyle(
                            color: selectedFoodType == 'all' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      ..._allFoodTypes.map((ft) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(ft),
                          selected: selectedFoodType == ft,
                          onSelected: (_) => setState(() => selectedFoodType = ft),
                          selectedColor: Colors.orange,
                          labelStyle: TextStyle(
                            color: selectedFoodType == ft ? Colors.white : Colors.black87,
                            fontSize: 13,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

            // ========== Content Area ==========
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // Note banner เมื่อใช้ fallback location
                          if (locationNote.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.orange.shade50,
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      locationNote,
                                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text('ไม่มีข้อมูลร้านอาหาร'));
                              }

                              final docs = snapshot.data!.docs;
                              final List<Map<String, dynamic>> nearbyRestaurants = [];

                              for (final doc in docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final lat = (data['latitude'] as num?)?.toDouble();
                                final lng = (data['longitude'] as num?)?.toDouble();

                                if (lat == null || lng == null || currentPosition == null) continue;

                                final distanceInMeters = geo.Geolocator.distanceBetween(
                                  currentPosition!.latitude,
                                  currentPosition!.longitude,
                                  lat,
                                  lng,
                                );

                                if (distanceInMeters <= 1500) {
                                  nearbyRestaurants.add({
                                    'id': doc.id,
                                    'data': data,
                                    'distanceKm': distanceInMeters / 1000,
                                  });
                                }
                              }

                              nearbyRestaurants.sort(
                                (a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double),
                              );

                              // filter foodType
                              final filtered = selectedFoodType == 'all'
                                  ? nearbyRestaurants
                                  : nearbyRestaurants.where((item) {
                                      final data = item['data'] as Map<String, dynamic>;
                                      final foodTypes = List<String>.from(data['foodTypes'] ?? []);
                                      return foodTypes.contains(selectedFoodType);
                                    }).toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      selectedFoodType == 'all'
                                          ? 'ไม่พบร้านอาหารในระยะ 1.5 กม.'
                                          : 'ไม่พบร้าน "$selectedFoodType" ในระยะ 1.5 กม.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final data = item['data'] as Map<String, dynamic>;
                                  final distanceKm = item['distanceKm'] as double;
                                  final id = item['id'] as String;

                                  final String name = data['name'] ?? 'ไม่มีชื่อร้าน';
                                  final String desc = data['desc'] ?? '';
                                  final String imageUrl = data['imageUrl'] ?? '';
                                  final String rating = data['avgRating']?.toString() ?? '0.0';
                                  final List<dynamic> foodTypes = data['foodTypes'] ?? [];

                                  return InkWell(
                                    onTap: () => showRestaurantDetailSheet(
                                      context: context,
                                      data: data,
                                      restaurantId: id,
                                      currentUserId: currentUserId,
                                      userRole: _userRole,
                                      distanceKm: distanceKm,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.orange.shade100),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 82,
                                            height: 82,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(16),
                                              image: imageUrl.isNotEmpty
                                                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                                  : null,
                                            ),
                                            child: imageUrl.isEmpty
                                                ? const Icon(Icons.image, color: Colors.grey)
                                                : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  desc,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                                // foodType chips
                                                if (foodTypes.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 5),
                                                    child: Wrap(
                                                      spacing: 4,
                                                      children: foodTypes.take(3).map((t) => Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange.shade50,
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(color: Colors.orange.shade200),
                                                        ),
                                                        child: Text(
                                                          t.toString(),
                                                          style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                                                        ),
                                                      )).toList(),
                                                    ),
                                                  ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.orange),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${distanceKm.toStringAsFixed(2)} กม.',
                                                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    const Icon(Icons.star, size: 14, color: Colors.orange),
                                                    const SizedBox(width: 2),
                                                    Text(rating, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
