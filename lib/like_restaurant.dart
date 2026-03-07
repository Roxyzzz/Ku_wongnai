import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'map_page.dart';
import 'feature/favorite_button.dart';

class LikeRestaurantPage extends StatefulWidget {
  const LikeRestaurantPage({super.key});

  @override
  State<LikeRestaurantPage> createState() => _LikeRestaurantPageState();
}

class _LikeRestaurantPageState extends State<LikeRestaurantPage> {
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showRestaurantDetails(BuildContext context, Map<String, dynamic> data, String restaurantId) {
    String name = data['name'] ?? 'ไม่มีชื่อร้าน';
    String desc = data['desc'] ?? 'ไม่มีรายละเอียด';
    String imageUrl = data['imageUrl'] ?? '';
    String openTime = data['openTime'] ?? '-';
    String closeTime = data['closeTime'] ?? '-';
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text('รายละเอียดร้านอาหาร',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                  ? const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                  : null,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                FavoriteButton(
                  restaurantId: restaurantId,
                  currentUserId: currentUserId,
                ),
              ],
            ),
            Text('เวลาทำการ: $openTime - $closeTime',
                style: const TextStyle(color: Colors.orange, fontSize: 13)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (lat != null && lng != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RouteMapPage(destName: name, destLat: lat, destLng: lng)),
                        );
                      }
                    },
                    icon: const Icon(Icons.map, color: Colors.blue),
                    label: const Text('แผนที่', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85B2A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ปิด', style: TextStyle(color: Colors.white)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ร้านอาหารที่ถูกใจ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        // เอาปุ่ม Back ด้านซ้ายบนออก เพราะเรามีปุ่ม Home ข้างล่างแล้ว
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          List<dynamic> favoriteIds = userData?['favoriteRestaurants'] ?? [];

          if (favoriteIds.isEmpty) {
            return const Center(
              child: Text('คุณยังไม่มีร้านอาหารที่ถูกใจ', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
            builder: (context, restSnapshot) {
              if (restSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!restSnapshot.hasData) {
                return const Center(child: Text('ไม่มีข้อมูลร้านอาหาร'));
              }

              var favoriteRestaurants = restSnapshot.data!.docs.where((doc) {
                return favoriteIds.contains(doc.id);
              }).toList();

              if (favoriteRestaurants.isEmpty) {
                return const Center(
                  child: Text('คุณยังไม่มีร้านอาหารที่ถูกใจ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: favoriteRestaurants.length,
                itemBuilder: (context, index) {
                  var doc = favoriteRestaurants[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return FavoriteRestaurantCard(
                    data: data,
                    onTap: () => _showRestaurantDetails(context, data, doc.id),
                  );
                },
              );
            },
          );
        },
      ),
      
      // ==========================================
      // เพิ่มแถบเมนูด้านล่างเข้ามาในหน้านี้ด้วย
      // ==========================================
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 60,
        decoration: BoxDecoration(
            color: const Color(0xFFE85B2A),
            borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ปุ่ม Home - กดแล้วย้อนกลับไปหน้า MainPage
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white), // ไอคอนโปร่ง
              onPressed: () {
                Navigator.pop(context); 
              },
            ),
            // ปุ่ม Favorite - อยู่หน้านี้อยู่แล้ว เลยเป็นไอคอนทึบ
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.white), // ไอคอนทึบ
              onPressed: () {
                // ไม่ต้องทำอะไร
              },
            ),
            // ปุ่ม Settings
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
      // ==========================================
    );
  }
}

class FavoriteRestaurantCard extends StatelessWidget {
  final VoidCallback onTap;
  final Map<String, dynamic> data;

  const FavoriteRestaurantCard({super.key, required this.onTap, required this.data});

  @override
  Widget build(BuildContext context) {
    String name = data['name'] ?? 'ไม่มีชื่อ';
    String rating = data['avgRating']?.toString() ?? '0.0';
    String imageUrl = data['imageUrl'] ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      Text(' $rating',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: imageUrl.isNotEmpty ? Colors.white : Colors.black)),
                      const Spacer(),
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: imageUrl.isNotEmpty ? Colors.white : Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}