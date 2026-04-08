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

  Future<void> _toggleFavoriteFirebase(bool isCurrentlyFavorite) async {
    if (currentUserId.isEmpty) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);

    try {
      if (isCurrentlyFavorite) {
        await userRef.update({
          'favoriteRestaurants': FieldValue.arrayRemove([restaurantId])
        });
      } else {
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
      return const IconButton(
        onPressed: null,
        icon: Icon(Icons.favorite_border, color: Colors.grey),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return const IconButton(
            onPressed: null,
            icon: Icon(Icons.favorite_border, color: Colors.grey),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        List<dynamic> favoriteRestaurants = userData?['favoriteRestaurants'] ?? [];

        // เช็คว่า ID ร้านอยู่ใน user ป่าว
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