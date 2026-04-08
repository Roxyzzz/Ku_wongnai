import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String address,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Create user failed (user is null)');
    }

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': name.trim(),
      'address': address.trim(),
      'role': 'user',
      'registeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'favoriteRestaurants': [],
    });
  }

  Future<void> updateProfile({
    String? name,
    String? address,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await _db.collection('users').doc(user.uid).set({
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}