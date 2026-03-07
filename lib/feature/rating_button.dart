import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingButton extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final String currentUserId;

  const RatingButton({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.currentUserId,
  });

  // ย้ายฟังก์ชัน Pop-up มาไว้ในไฟล์นี้
  void _showRatingBottomSheet(BuildContext context) {
    int currentRating = 0; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 20),
                  const Text('ให้คะแนนความพึงพอใจ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(restaurantName, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 45,
                        icon: Icon(
                          index < currentRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          setState(() {
                            currentRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  
                  Text(
                    currentRating == 0 ? 'แตะที่ดาวเพื่อให้คะแนน' : 'คุณให้ $currentRating ดาว',
                    style: TextStyle(
                      color: currentRating == 0 ? Colors.grey : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),

                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'เขียนรีวิวเพิ่มเติม (ไม่บังคับ)...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85B2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      onPressed: currentRating == 0 
                        ? null 
                        : () async {
                            Navigator.pop(context); // ปิดหน้าต่าง Popup

                            if (currentUserId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาล็อกอินก่อนให้คะแนน')));
                              return; 
                            }

                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังบันทึกคะแนน...')));

                            final restRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
                            final reviewRef = restRef.collection('reviews').doc(currentUserId);

                            try {
                              await FirebaseFirestore.instance.runTransaction((transaction) async {
                                final restSnapshot = await transaction.get(restRef);
                                if (!restSnapshot.exists) return;

                                final reviewSnapshot = await transaction.get(reviewRef);

                                int currentCount = restSnapshot.data()?['ratingCount'] ?? 0;
                                num currentSum = restSnapshot.data()?['ratingSum'] ?? 0;

                                if (reviewSnapshot.exists) {
                                  num oldRating = reviewSnapshot.data()?['rating'] ?? 0;
                                  currentSum = currentSum - oldRating + currentRating;
                                } else {
                                  currentCount += 1;
                                  currentSum += currentRating;
                                }

                                double newAvg = currentSum / currentCount;
                                double roundedAvg = double.parse(newAvg.toStringAsFixed(1));

                                transaction.update(restRef, {
                                  'ratingCount': currentCount,
                                  'ratingSum': currentSum,
                                  'avgRating': roundedAvg,
                                });

                                transaction.set(reviewRef, {
                                  'userId': currentUserId,
                                  'rating': currentRating,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                              });

                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกคะแนนสำเร็จ ขอบคุณครับ!')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด ลองใหม่อีกครั้ง')));
                            }
                          },
                      child: const Text('ส่งคะแนน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // โค้ดสร้างปุ่มโชว์ในหน้ารายละเอียดร้าน
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[50],
          foregroundColor: Colors.orange,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          Navigator.pop(context); // ปิดหน้ารายละเอียดร้านก่อน
          _showRatingBottomSheet(context); // เรียกหน้าให้คะแนนขึ้นมาแทน
        },
        icon: const Icon(Icons.star_rate_rounded),
        label: const Text('ให้คะแนนร้านนี้', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}