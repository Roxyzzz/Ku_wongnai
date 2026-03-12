import 'package:flutter/material.dart';
import 'package:ku_wongnai/utils/restaurant_utils.dart';

/// การ์ดแสดงร้านอาหารในรูปแบบ Grid
class RestaurantCard extends StatelessWidget {
  final VoidCallback onTap;
  final Map<String, dynamic> data;

  const RestaurantCard({
    super.key,
    required this.onTap,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'ไม่มีชื่อ';
    final String rating = data['avgRating']?.toString() ?? '0.0';
    final String imageUrl = data['imageUrl'] ?? '';
    final List<dynamic> foodTypes = data['foodTypes'] ?? [];
    final openTime = data['openTime'];
    final closeTime = data['closeTime'];

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
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                )
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
                      Text(
                        ' $rating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: imageUrl.isNotEmpty ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // แสดง foodType tag อันแรก (ถ้ามี)
                  if (foodTypes.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        foodTypes.first.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: imageUrl.isNotEmpty ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Open/Closed badge มุมขวาบน
            Positioned(
              top: 8,
              right: 8,
              child: OpenStatusBadge(
                openTime: openTime,
                closeTime: closeTime,
                small: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
