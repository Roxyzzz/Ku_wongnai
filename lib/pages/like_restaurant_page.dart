import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ku_wongnai/widgets/restaurant_card.dart';
import 'package:ku_wongnai/widgets/restaurant_detail_sheet.dart';
import 'package:ku_wongnai/pages/nearby_restaurants_page.dart';
import 'package:ku_wongnai/pages/profile_page.dart';

class LikeRestaurantPage extends StatefulWidget {
  const LikeRestaurantPage({super.key});

  @override
  State<LikeRestaurantPage> createState() => _LikeRestaurantPageState();
}

class _LikeRestaurantPageState extends State<LikeRestaurantPage> {
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showRestaurantDetails(BuildContext context, Map<String, dynamic> data, String restaurantId) {
    showRestaurantDetailSheet(
      context: context,
      data: data,
      restaurantId: restaurantId,
      currentUserId: currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      body: SafeArea(
        child: Column(
          children: [
            // ========== Header ==========
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 20, bottom: 20),
              child: Row(
                children: const [
                  Text(
                    'ร้านอาหารที่ถูกใจ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
            
            // ========== Content ==========
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: StreamBuilder<DocumentSnapshot>(
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
                          padding: const EdgeInsets.all(25),
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
                            return RestaurantCard(
                              data: data,
                              onTap: () => _showRestaurantDetails(context, data, doc.id),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE85B2A),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) => const NearbyRestaurantsPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) => const ProfilePage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}