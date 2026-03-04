import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String selectedCategory = 'all';
  String searchQuery = '';

  void _showRestaurantDetails(BuildContext context, Map<String, dynamic> data) {
    bool isFavorite = false;

    String name = data['name'] ?? 'ไม่มีชื่อร้าน';
    String desc = data['desc'] ?? 'ไม่มีรายละเอียด';
    String imageUrl = data['imageUrl'] ?? '';
    String openTime = data['openTime'] ?? '-';
    String closeTime = data['closeTime'] ?? '-';
    final lat = (data['latitude'] as num?)?.toDouble();
  final lng = (data['longitude'] as num?)?.toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
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
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text('รายละเอียดร้านอาหาร',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey))
                    : null,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              Text('เวลาทำการ: $openTime - $closeTime',
                  style: const TextStyle(color: Colors.orange, fontSize: 13)),
              const SizedBox(height: 8),
              Text(desc, style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute( builder: (_) => RouteMapPage(destName: name, destLat: lat!, destLng: lng!
                        ),
                        ),
                        );
                      },

                      icon: const Icon(Icons.map, color: Colors.blue),
                      label: const Text('แผนที่',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85B2A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิดหน้าต่าง',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Stream<QuerySnapshot> _getRestaurantStream() {
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');

    if (selectedCategory == 'all') {
      return restaurants.snapshots();
    } else {
      return restaurants
          .where('category', isEqualTo: selectedCategory)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25)),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          suffixIcon: Icon(Icons.tune, color: Colors.orange),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Icon(Icons.notifications_none, color: Colors.white),
                  const SizedBox(width: 10),
                  const Icon(Icons.person_outline, color: Colors.white),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => selectedCategory = 'all'),
                            child: CategoryItem(
                                label: 'ทั้งหมด',
                                icon: Icons.apps,
                                isSelected: selectedCategory == 'all'),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => selectedCategory = 'food'),
                            child: CategoryItem(
                                label: 'ร้านอาหาร',
                                icon: Icons.restaurant,
                                isSelected: selectedCategory == 'food'),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => selectedCategory = 'cafe'),
                            child: CategoryItem(
                                label: 'คาเฟ่',
                                icon: Icons.coffee,
                                isSelected: selectedCategory == 'cafe'),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => selectedCategory = 'drink'),
                            child: CategoryItem(
                                label: 'เครื่องดื่ม',
                                icon: Icons.local_drink,
                                isSelected: selectedCategory == 'drink'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text('ร้านอาหารแนะนำ',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      StreamBuilder<QuerySnapshot>(
                        stream: _getRestaurantStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(
                                  child: Text('ไม่มีข้อมูลในหมวดหมู่นี้')),
                            );
                          }

                          var restaurants = snapshot.data!.docs;

                          if (searchQuery.isNotEmpty) {
                            restaurants = restaurants.where((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              var name = (data['name'] ?? '').toString().toLowerCase();
                              return name.contains(searchQuery.toLowerCase());
                            }).toList();
                          }

                          if (restaurants.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(
                                  child: Text('ไม่พบร้านอาหารที่ค้นหา')),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: restaurants.length,
                            itemBuilder: (context, index) {
                              var data = restaurants[index].data()
                                  as Map<String, dynamic>;
                              return RestaurantCardPlaceholder(
                                data: data,
                                onTap: () =>
                                    _showRestaurantDetails(context, data),
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 60,
        decoration: BoxDecoration(
            color: const Color(0xFFE85B2A),
            borderRadius: BorderRadius.circular(30)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home_outlined, color: Colors.white),
            Icon(Icons.favorite_border, color: Colors.white),
            Icon(Icons.settings_outlined, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.orange[50],
              shape: BoxShape.circle),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
      ],
    );
  }
}

class RestaurantCardPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  final Map<String, dynamic> data;

  const RestaurantCardPlaceholder(
      {super.key, required this.onTap, required this.data});

  @override
  Widget build(BuildContext context) {
    String name = data['name'] ?? 'ไม่มีชื่อ';
    String rating = data['avgRating']?.toString() ?? '0.0';
    String imageUrl = data['imageUrl'] ?? '';

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
                      Colors.black.withOpacity(0.3), BlendMode.darken))
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
                      Text(' $rating',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: imageUrl.isNotEmpty
                                  ? Colors.white
                                  : Colors.black)),
                      const Spacer(),
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            imageUrl.isNotEmpty ? Colors.white : Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}