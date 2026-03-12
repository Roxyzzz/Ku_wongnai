import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ku_wongnai/widgets/restaurant_card.dart';
import 'package:ku_wongnai/widgets/category_item.dart';
import 'package:ku_wongnai/widgets/restaurant_detail_sheet.dart';
import 'package:ku_wongnai/pages/nearby_restaurants_page.dart';
import 'package:ku_wongnai/pages/like_restaurant_page.dart';
import 'package:ku_wongnai/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String selectedCategory = 'all';
  String selectedFoodType = 'all';
  String searchQuery = '';

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // หมวดหมู่ใหญ่
  static const _categories = [
    {'value': 'all', 'label': 'ทั้งหมด', 'icon': Icons.apps},
    {'value': 'food', 'label': 'ร้านอาหาร', 'icon': Icons.restaurant},
    {'value': 'cafe', 'label': 'คาเฟ่', 'icon': Icons.coffee},
    {'value': 'drink', 'label': 'เครื่องดื่ม', 'icon': Icons.local_drink},
  ];

  // foodTypes ตาม category
  static const Map<String, List<String>> _foodTypesByCategory = {
    'food': ['ก๋วยเตี๋ยว', 'ข้าวราดแกง', 'อาหารตามสั่ง', 'ส้มตำ', 'ยำ', 'เนื้อย่าง', 'ปิ้งย่าง', 'ผัดไทย', 'อาหารญี่ปุ่น'],
    'cafe': ['กาแฟ', 'ชา', 'เบเกอรี่', 'ชาไข่มุก', 'ชาผลไม้', 'ชานม', 'น้ำผลไม้', 'สมูทตี้', 'เครื่องดื่มสุขภาพ'],
    'drink': ['กาแฟ', 'ชา', 'เครื่องดื่ม', 'โยเกิร์ต', 'สมูทตี้'],
  };

  Stream<QuerySnapshot> _getRestaurantStream() {
    final col = FirebaseFirestore.instance.collection('restaurants');
    if (selectedCategory == 'all') return col.snapshots();
    return col.where('category', isEqualTo: selectedCategory).snapshots();
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    var result = docs;

    // filter ชื่อร้าน
    if (searchQuery.isNotEmpty) {
      result = result.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final desc = (data['desc'] ?? '').toString().toLowerCase();
        final q = searchQuery.toLowerCase();
        return name.contains(q) || desc.contains(q);
      }).toList();
    }

    // filter foodType
    if (selectedFoodType != 'all') {
      result = result.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final foodTypes = List<String>.from(data['foodTypes'] ?? []);
        return foodTypes.contains(selectedFoodType);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final foodTypes = selectedCategory != 'all'
        ? _foodTypesByCategory[selectedCategory] ?? []
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      body: SafeArea(
        child: Column(
          children: [
            // ========== Search Bar ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'ค้นหาร้านอาหาร...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.tune, color: Colors.orange),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========== หมวดหมู่ใหญ่ ==========
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _categories.map((cat) {
                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedCategory = cat['value'] as String;
                              selectedFoodType = 'all'; // reset food type
                            }),
                            child: CategoryItem(
                              label: cat['label'] as String,
                              icon: cat['icon'] as IconData,
                              isSelected: selectedCategory == cat['value'],
                            ),
                          );
                        }).toList(),
                      ),

                      // ========== foodType Chip Filter ==========
                      if (foodTypes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // ปุ่ม "ทั้งหมด"
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('ทั้งหมด'),
                                  selected: selectedFoodType == 'all',
                                  onSelected: (_) => setState(() => selectedFoodType = 'all'),
                                  selectedColor: Colors.orange,
                                  labelStyle: TextStyle(
                                    color: selectedFoodType == 'all' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: Colors.orange.shade50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colors.orange.shade200),
                                  ),
                                ),
                              ),
                              // foodType chips
                              ...foodTypes.map((ft) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(ft),
                                  selected: selectedFoodType == ft,
                                  onSelected: (_) => setState(() => selectedFoodType = ft),
                                  selectedColor: Colors.orange,
                                  labelStyle: TextStyle(
                                    color: selectedFoodType == ft ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: Colors.orange.shade50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colors.orange.shade200),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Text(
                        'ร้านอาหารแนะนำ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),

                      // ========== Restaurant Grid ==========
                      StreamBuilder<QuerySnapshot>(
                        stream: _getRestaurantStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(child: Text('ไม่มีข้อมูลในหมวดหมู่นี้')),
                            );
                          }

                          final filtered = _filterDocs(snapshot.data!.docs);

                          if (filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(child: Text('ไม่พบร้านอาหารที่ค้นหา')),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return RestaurantCard(
                                data: data,
                                onTap: () => showRestaurantDetailSheet(
                                  context: context,
                                  data: data,
                                  restaurantId: doc.id,
                                  currentUserId: currentUserId,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ========== Bottom Nav ==========
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
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyRestaurantsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) => const LikeRestaurantPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
