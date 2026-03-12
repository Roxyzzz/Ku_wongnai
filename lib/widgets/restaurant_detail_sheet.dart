import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ku_wongnai/pages/map_page.dart';
import 'package:ku_wongnai/widgets/favorite_button.dart';
import 'package:ku_wongnai/widgets/rating_button.dart';
import 'package:ku_wongnai/utils/restaurant_utils.dart';

/// Bottom sheet แสดงรายละเอียดร้านอาหาร — ใช้ร่วมกันได้ทุกหน้า
void showRestaurantDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> data,
  required String restaurantId,
  required String currentUserId,
  double? distanceKm, // ถ้าส่งมาจะแสดงระยะทาง (ใช้ใน NearbyPage)
}) {
  final String name = data['name'] ?? 'ไม่มีชื่อร้าน';
  final String desc = data['desc'] ?? 'ไม่มีรายละเอียด';
  final String imageUrl = data['imageUrl'] ?? '';
  final String openTime = data['openTime'] ?? '-';
  final String closeTime = data['closeTime'] ?? '-';
  final lat = (data['latitude'] as num?)?.toDouble();
  final lng = (data['longitude'] as num?)?.toDouble();
  final List<dynamic> foodTypes = data['foodTypes'] ?? [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85, // ให้สูงขึ้นเพื่อแสดงรีวิว
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
              // รูปภาพร้าน
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
              // ชื่อร้าน + ปุ่ม Favorite
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
              // ระยะทาง (ถ้ามี)
              if (distanceKm != null) ...[
                const SizedBox(height: 4),
                Text(
                  'ระยะทางประมาณ ${distanceKm.toStringAsFixed(2)} กม.',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'เวลาทำการ: $openTime - $closeTime',
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                  OpenStatusBadge(
                    openTime: data['openTime'],
                    closeTime: data['closeTime'],
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(desc, style: const TextStyle(color: Colors.grey)),
              // foodTypes chips
              if (foodTypes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: foodTypes.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        t.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 15),
              
              const Divider(),
              const Text(
                'รีวิวจากผู้ใช้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // ส่วนแสดงรีวิว
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .collection('reviews')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดรีวิว'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reviews = snapshot.data!.docs;

                    if (reviews.isEmpty) {
                      return Center(
                        child: Text(
                          'ยังไม่มีรีวิวสำหรับร้านนี้\nกดให้คะแนนเป็นคนแรกเลย!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 10),
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final revStr = reviews[index].data() as Map<String, dynamic>;
                        final double score = (revStr['rating'] ?? 0).toDouble();
                        final String user = revStr['userName'] ?? 'ผู้ใช้วงใน';
                        final String comment = revStr['comment'] ?? '';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.orange.shade100,
                                  child: Text(
                                    user.isNotEmpty ? user[0].toUpperCase() : 'U',
                                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      starIdx < score ? Icons.star : Icons.star_border,
                                      size: 14,
                                      color: Colors.orange,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                comment,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 15),
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
        );
      },
    ),
  );
}
