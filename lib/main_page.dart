import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  // ฟังก์ชันสำหรับแสดงรายละเอียดเมื่อกดที่ร้านอาหาร
  void _showRestaurantDetails(BuildContext context) {
    // สร้างตัวแปรเก็บสถานะการถูกใจ (เริ่มต้นเป็น false คือยังไม่กด)
    bool isFavorite = false; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder( // ใช้ StatefulBuilder เพื่อให้ setState ภายใน Pop-up ได้
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
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
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey))),
                const SizedBox(height: 15),
                
                // --- ส่วนปุ่มหัวใจที่กดแล้วเปลี่ยนสถานะได้ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ร้านอาหารตัวอย่างที่เลือก',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isFavorite = !isFavorite; // สลับสถานะเมื่อกด
                        });
                      },
                      // ตรวจสอบเงื่อนไข: ถ้า isFavorite เป็น true ให้เป็นไอคอนทึบ ถ้า false ให้เป็นโปร่ง
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border, 
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                // ------------------------------------------------
                
                const Text(
                    'รายละเอียดเพิ่มเติมของร้านนี้ เช่น เมนูเด็ด เวลาเปิดปิด หรือตำแหน่งที่ตั้งของร้าน',
                    style: TextStyle(color: Colors.grey)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85B2A)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ปิดหน้าต่าง',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
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
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25)),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Search', style: TextStyle(color: Colors.grey)),
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          CategoryItem(label: 'ทั้งหมด', icon: Icons.apps),
                          CategoryItem(
                              label: 'ร้านอาหาร', icon: Icons.restaurant),
                          CategoryItem(label: 'คาเฟ่', icon: Icons.coffee),
                          CategoryItem(
                              label: 'เครื่องดื่ม', icon: Icons.local_drink),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ร้านอาหารแนะนำ',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                              onPressed: () {},
                              child: const Text('View All >',
                                  style: TextStyle(color: Colors.orange))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return RestaurantCardPlaceholder(
                              onTap: () => _showRestaurantDetails(context));
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
  const CategoryItem({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: Colors.orange[50], shape: BoxShape.circle),
          child: Icon(icon, color: Colors.orange),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class RestaurantCardPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const RestaurantCardPlaceholder({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
        child: const Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  Text(' 5.0',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Icon(Icons.favorite, color: Colors.red, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}