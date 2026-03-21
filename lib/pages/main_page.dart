import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ku_wongnai/widgets/restaurant_card.dart';
import 'package:ku_wongnai/widgets/category_item.dart';
import 'package:ku_wongnai/widgets/restaurant_detail_sheet.dart';
import 'package:ku_wongnai/pages/nearby_restaurants_page.dart';
import 'package:ku_wongnai/pages/like_restaurant_page.dart';
import 'package:ku_wongnai/pages/profile_page.dart';
import 'package:ku_wongnai/pages/add_restaurant_page.dart';
import 'package:ku_wongnai/pages/admin_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String selectedCategory = 'all';
  String selectedFoodType = 'all';
  String searchQuery = '';
  String _userRole = 'user';

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = (doc.data()?['role'] ?? 'user').toString();
        });
      }
    } catch (_) {}
  }

  static const _categories = [
    {'value': 'all', 'label': 'ทั้งหมด', 'icon': Icons.apps},
    {'value': 'food', 'label': 'ร้านอาหาร', 'icon': Icons.restaurant},
    {'value': 'cafe', 'label': 'คาเฟ่', 'icon': Icons.coffee},
    {'value': 'drink', 'label': 'เครื่องดื่ม', 'icon': Icons.local_drink},
  ];

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
    if (searchQuery.isNotEmpty) {
      result = result.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final desc = (data['desc'] ?? '').toString().toLowerCase();
        final q = searchQuery.toLowerCase();
        return name.contains(q) || desc.contains(q);
      }).toList();
    }
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
            // ========== Search Bar + Admin Button ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                  if (_userRole == 'admin') ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPage()),
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85B2A),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE85B2A).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                      ),
                    ),
                  ],
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(25, 25, 25, 100),
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
                              selectedFoodType = 'all';
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

                      // ========== Banner เพิ่มร้านอาหาร ==========
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddRestaurantPage()),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE85B2A), Color(0xFFFF8C42)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE85B2A).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.add_business_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'เพิ่มร้านอาหารของคุณ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'แชร์ร้านโปรดให้คนอื่นรู้จัก',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

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
                            return Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text('ยังไม่มีร้านอาหารในหมวดหมู่นี้',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final filtered = _filterDocs(snapshot.data!.docs);

                          if (filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text('ไม่พบร้านอาหารที่ค้นหา',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
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
                                  userRole: _userRole,
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

      // ========== Bottom Nav (clean, no gap) ==========
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE85B2A),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE85B2A).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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
                    pageBuilder: (context, animation1, animation2) =>
                        const LikeRestaurantPage(),
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
                ).then((_) => _loadUserRole());
              },
            ),
          ],
        ),
      ),
    );
  }
}
