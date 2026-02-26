import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F), // สีเหลือง Amber
      body: SafeArea(
        child: Column(
          children: [
            // --- ส่วน Search และ Profile ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          const Text('Search', style: TextStyle(color: Colors.grey)),
                          Spacer(),
                          Icon(Icons.tune, color: Colors.orange),
                        ],
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

            // --- ส่วนเนื้อหาหลักพื้นหลังสีขาว ---
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
                      // --- หมวดหมู่ (Categories) ---
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          CategoryItem(label: 'ทั้งหมด'),
                          CategoryItem(label: 'ร้านอาหาร'),
                          CategoryItem(label: 'คาเฟ่'),
                          CategoryItem(label: 'เครื่องดื่ม'),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // --- หัวข้อร้านอาหารแนะนำ ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ร้านอาหารแนะนำ',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All >', style: TextStyle(color: Colors.orange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // --- รายการร้านอาหาร (Grid) ---
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return const RestaurantCardPlaceholder();
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
      // --- แถบเมนูด้านล่าง (แก้ไขไอคอนเป็น Settings แล้ว) ---
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE85B2A), // สีส้มเข้ม
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home_outlined, color: Colors.white),
            Icon(Icons.favorite_border, color: Colors.white),
            // เปลี่ยนจาก Icons.headset_mic_outlined เป็น Icons.settings_outlined
            Icon(Icons.settings_outlined, color: Colors.white), 
          ],
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  const CategoryItem({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
          child: const Icon(Icons.restaurant, color: Colors.orange),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class RestaurantCardPlaceholder extends StatelessWidget {
  const RestaurantCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200], 
        borderRadius: BorderRadius.circular(20)
      ),
      child: const Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 16),
                Text(' 5.0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Spacer(),
                Icon(Icons.favorite, color: Colors.red, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}