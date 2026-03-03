import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  DocumentReference<Map<String, dynamic>> _favDoc(String restaurantId) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(restaurantId);
  }

  Stream<bool> isFavoriteStream(String restaurantId) {
    return _favDoc(restaurantId).snapshots().map((d) => d.exists);
  }

  Future<void> toggleFavorite({
    required String restaurantId,
    required String name,
    required String address,
    required String category,
    String? imageUrl,
  }) async {
    final ref = _favDoc(restaurantId);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'restaurantId': restaurantId,
        'name': name,
        'address': address,
        'category': category,
        'imageUrl': imageUrl ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> favoritesStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }
}