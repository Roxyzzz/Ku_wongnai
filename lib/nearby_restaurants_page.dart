import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'map_page.dart';
import 'feature/favorite_button.dart';
import 'feature/rating_button.dart';

class NearbyRestaurantsPage extends StatefulWidget {
  const NearbyRestaurantsPage({super.key});

  @override
  State<NearbyRestaurantsPage> createState() => _NearbyRestaurantsPageState();
}

class _NearbyRestaurantsPageState extends State<NearbyRestaurantsPage> {
  bool isLoading = true;
  String errorMessage = '';
  geo.Position? currentPosition;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLoading = false;
          errorMessage = 'กรุณาเปิด Location Service';
        });
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();

      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.denied) {
        setState(() {
          isLoading = false;
          errorMessage = 'ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง';
        });
        return;
      }

      if (permission == geo.LocationPermission.deniedForever) {
        setState(() {
          isLoading = false;
          errorMessage = 'กรุณาอนุญาตตำแหน่งจาก Settings';
        });
        return;
      }

      final pos = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      setState(() {
        currentPosition = pos;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'ไม่สามารถโหลดตำแหน่งได้';
      });
    }
  }

  void _showRestaurantDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String restaurantId,
    double distanceKm,
  ) {
    final String name = data['name'] ?? 'ไม่มีชื่อร้าน';
    final String desc = data['desc'] ?? 'ไม่มีรายละเอียด';
    final String imageUrl = data['imageUrl'] ?? '';
    final String openTime = data['openTime'] ?? '-';
    final String closeTime = data['closeTime'] ?? '-';
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'รายละเอียดร้านอาหาร',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    )
                  : null,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FavoriteButton(
                  restaurantId: restaurantId,
                  currentUserId: currentUserId,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ระยะทางประมาณ ${distanceKm.toStringAsFixed(2)} กม.',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'เวลาทำการ: $openTime - $closeTime',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            RatingButton(
              restaurantId: restaurantId,
              restaurantName: name,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (lat != null && lng != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RouteMapPage(
                              destName: name,
                              destLat: lat,
                              destLng: lng,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.map, color: Colors.blue),
                    label: const Text(
                      'นำทาง',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85B2A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ปิดหน้าต่าง',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
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
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('restaurants')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('ไม่มีข้อมูลร้านอาหาร'),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        final List<Map<String, dynamic>> nearbyRestaurants = [];

                        for (final doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final lat = (data['latitude'] as num?)?.toDouble();
                          final lng = (data['longitude'] as num?)?.toDouble();

                          if (lat == null || lng == null || currentPosition == null) {
                            continue;
                          }

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
                          (a, b) => (a['distanceKm'] as double)
                              .compareTo(b['distanceKm'] as double),
                        );

                        if (nearbyRestaurants.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'ไม่พบร้านอาหารในระยะ 1.5 กม.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: nearbyRestaurants.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = nearbyRestaurants[index];
                            final data = item['data'] as Map<String, dynamic>;
                            final distanceKm = item['distanceKm'] as double;
                            final id = item['id'] as String;

                            final String name = data['name'] ?? 'ไม่มีชื่อร้าน';
                            final String desc = data['desc'] ?? 'ไม่มีรายละเอียด';
                            final String imageUrl = data['imageUrl'] ?? '';
                            final String rating =
                                data['avgRating']?.toString() ?? '0.0';

                            return InkWell(
                              onTap: () => _showRestaurantDetails(
                                context,
                                data,
                                id,
                                distanceKm,
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
                                      color: Colors.black.withOpacity(0.04),
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
                                            ? DecorationImage(
                                                image: NetworkImage(imageUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: imageUrl.isEmpty
                                          ? const Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            desc,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${distanceKm.toStringAsFixed(2)} กม.',
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }
}