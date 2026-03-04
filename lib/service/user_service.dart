import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String address,
  }) async {
    // 1) Create user in FirebaseAuth
    final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Create user failed (user is null)');
    }

    // 2) Save user data to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': name.trim(),
      'address': address.trim(),
      'registeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'favoriteRestaurants': [], 
    });
  }
}