import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ku_wongnai/pages/map_page.dart';
import 'package:ku_wongnai/widgets/favorite_button.dart';
import 'package:ku_wongnai/widgets/rating_button.dart';
import 'package:ku_wongnai/utils/restaurant_utils.dart';
import 'package:ku_wongnai/widgets/storage_image_widget.dart';

/// เปิดดูรูปเต็มจอ
void _showFullImage(BuildContext context, String imageUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, progress) =>
                  progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// ลบรีวิว + อัปเดตคะแนนเฉลี่ย (เฉพาะ admin)
Future<void> _deleteReview(
    BuildContext context, String restaurantId, String reviewDocId, num rating) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('ลบรีวิว'),
      content: const Text('คุณต้องการลบรีวิวนี้ใช่ไหม?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('ลบ', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final restRef =
        FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
    final reviewRef = restRef.collection('reviews').doc(reviewDocId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final restSnap = await transaction.get(restRef);
      if (!restSnap.exists) return;

      int count = restSnap.data()?['ratingCount'] ?? 0;
      num sum = restSnap.data()?['ratingSum'] ?? 0;

      count = (count - 1).clamp(0, 9999);
      sum = (sum - rating).clamp(0, 99999);
      final double newAvg = count == 0 ? 0 : sum / count;

      transaction.delete(reviewRef);
      transaction.update(restRef, {
        'ratingCount': count,
        'ratingSum': sum,
        'avgRating': double.parse(newAvg.toStringAsFixed(1)),
      });
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบรีวิวสำเร็จ')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }
}

/// Bottom sheet แสดงรายละเอียดร้านอาหาร — ใช้ร่วมกันได้ทุกหน้า
void showRestaurantDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> data,
  required String restaurantId,
  required String currentUserId,
  String userRole = 'user',   // ส่ง 'admin' มาเพื่อเปิดปุ่มลบรีวิว
  double? distanceKm,
}) {
  final String name = data['name'] ?? 'ไม่มีชื่อร้าน';
  final String desc = data['desc'] ?? 'ไม่มีรายละเอียด';
  final String? imagePath = data['imagePath'] as String?;
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
          height: MediaQuery.of(context).size.height * 0.85,
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
              // รูปภาพร้าน (Firebase Storage)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: StorageImageWidget(
                    storagePath: imagePath,
                    fit: BoxFit.cover,
                    height: 150,
                    width: double.infinity,
                    placeholder: Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
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
                    openTime: openTime,
                    closeTime: closeTime,
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(desc, style: const TextStyle(color: Colors.grey)),
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
              Row(
                children: [
                  const Text(
                    'รีวิวจากผู้ใช้',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (userRole == 'admin') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Admin Mode',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
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
                        final doc = reviews[index];
                        final revData = doc.data() as Map<String, dynamic>;
                        final double score = (revData['rating'] ?? 0).toDouble();
                        final String user = revData['userName'] ?? 'ผู้ใช้วงใน';
                        final String comment = revData['comment'] ?? '';
                        final String? reviewImageUrl = revData['imageUrl'] as String?;

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
                                // ปุ่มลบรีวิว (เฉพาะ admin)
                                if (userRole == 'admin') ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _deleteReview(
                                        context, restaurantId, doc.id, score),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.delete_outline,
                                          size: 16, color: Colors.red.shade600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                comment,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                            // รูปรีวิว — กดดูเต็มจอได้
                            if (reviewImageUrl != null && reviewImageUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showFullImage(context, reviewImageUrl),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        reviewImageUrl,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) =>
                                            progress == null
                                                ? child
                                                : const SizedBox(
                                                    height: 140,
                                                    child: Center(
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  ),
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      ),
                                    ),
                                    // icon ขยายมุมขวาล่าง
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.fullscreen,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
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
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
