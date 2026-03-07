import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteButton extends StatelessWidget {
  final String restaurantId;
  final String currentUserId;

  const FavoriteButton({
    super.key,
    required this.restaurantId,
    required this.currentUserId,
  });

  // ฟังก์ชันคุยกับ Firebase (ดึงมาจาก MainPage เดิม)
  Future<void> _toggleFavoriteFirebase(bool isCurrentlyFavorite) async {
    if (currentUserId.isEmpty) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);

    try {
      if (isCurrentlyFavorite) {
        // ถ้าเป็น Favorite อยู่แล้ว ให้กดลบออก
        await userRef.update({
          'favoriteRestaurants': FieldValue.arrayRemove([restaurantId])
        });
      } else {
        // ถ้ายังไม่เป็น ให้กดเพิ่มเข้าไป
        await userRef.update({
          'favoriteRestaurants': FieldValue.arrayUnion([restaurantId])
        });
      }
    } catch (e) {
      await userRef.set({
        'favoriteRestaurants': isCurrentlyFavorite ? [] : [restaurantId]
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      // ถ้าไม่ได้ล็อกอิน (ไม่มี UID) ให้โชว์ปุ่มเทาๆ กดไม่ได้
      return const IconButton(
        onPressed: null,
        icon: Icon(Icons.favorite_border, color: Colors.grey),
      );
    }

    // ใช้ StreamBuilder ไปดึงข้อมูล User คนนี้มาเช็คว่าเคยกดไลก์ร้านนี้หรือยัง
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          // ระหว่างรอโหลด ให้โชว์ปุ่มโปร่งๆ ไว้ก่อน
          return const IconButton(
            onPressed: null,
            icon: Icon(Icons.favorite_border, color: Colors.grey),
          );
        }

        // ดึง Array รายชื่อร้านที่ชอบออกมา
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        List<dynamic> favoriteRestaurants = userData?['favoriteRestaurants'] ?? [];

        // เช็คว่า ID ร้านนี้ อยู่ใน Array ของ User ไหม (ถ้าอยู่แปลว่าถูกใจแล้ว)
        bool isFavorite = favoriteRestaurants.contains(restaurantId);

        return IconButton(
          onPressed: () => _toggleFavoriteFirebase(isFavorite),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
        );
      },
    );
  }
}