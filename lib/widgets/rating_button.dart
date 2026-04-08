import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  void _showRatingBottomSheet(BuildContext context) {
    int currentRating = 0;
    final TextEditingController commentController = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

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
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 20),
                  const Text('ให้คะแนนความพึงพอใจ',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(restaurantName,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 45,
                        icon: Icon(
                          index < currentRating
                              ? Icons.star
                              : Icons.star_border,
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
                    currentRating == 0
                        ? 'แตะที่ดาวเพื่อให้คะแนน'
                        : 'คุณให้ $currentRating ดาว',
                    style: TextStyle(
                      color: currentRating == 0 ? Colors.grey : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ช่องกรอกข้อความรีวิว
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'เขียนรีวิวของคุณที่นี่ (ไม่บังคับ)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.orange),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== ส่วนเพิ่มรูปภาพ =====
                  Row(
                    children: [
                      // Preview รูปที่เลือก
                      if (selectedImage != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                      ],

                      // ปุ่มเลือกรูป
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.orange.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () async {
                            // แสดง dialog เลือกถ่ายรูปหรือเลือกจาก gallery
                            final source = await showDialog<ImageSource>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: const Text('เพิ่มรูปภาพ'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt,
                                          color: Colors.orange),
                                      title: const Text('ถ่ายรูป'),
                                      onTap: () => Navigator.pop(
                                          ctx, ImageSource.camera),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library,
                                          color: Colors.orange),
                                      title: const Text('เลือกจาก Gallery'),
                                      onTap: () => Navigator.pop(
                                          ctx, ImageSource.gallery),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (source == null) return;
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: source,
                              imageQuality: 75,
                            );
                            if (picked != null) {
                              setState(
                                  () => selectedImage = File(picked.path));
                            }
                          },
                          icon: Icon(Icons.add_photo_alternate,
                              color: Colors.orange.shade700),
                          label: Text(
                            selectedImage == null
                                ? 'เพิ่มรูปภาพ'
                                : 'เปลี่ยนรูปภาพ',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85B2A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      onPressed: (currentRating == 0 || isUploading)
                          ? null
                          : () async {
                              setState(() => isUploading = true);

                              final String comment =
                                  commentController.text.trim();
                              final authUser =
                                  FirebaseAuth.instance.currentUser;
                              final String userName =
                                  authUser?.displayName ??
                                      authUser?.email?.split('@').first ??
                                      'ผู้ใช้วงใน';

                              Navigator.pop(context);

                              if (currentUserId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('กรุณาล็อกอินก่อนให้คะแนน')));
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('กำลังบันทึกคะแนน...')));

                              // Upload รูปภาพ (ถ้ามี)
                              String? imageUrl;
                              if (selectedImage != null) {
                                try {
                                  final ref = FirebaseStorage.instance
                                      .ref()
                                      .child(
                                          'reviews/$restaurantId/${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                  await ref.putFile(selectedImage!);
                                  imageUrl = await ref.getDownloadURL();
                                } catch (uploadErr) {
                                  // แสดง error ให้ user รู้ว่า upload รูปไม่ได้
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'อัปโหลดรูปไม่สำเร็จ: $uploadErr'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return; // หยุดไม่บันทึก review ถ้า upload ล้มเหลว
                                }
                              }

                              final restRef = FirebaseFirestore.instance
                                  .collection('restaurants')
                                  .doc(restaurantId);
                              final reviewRef =
                                  restRef.collection('reviews').doc(currentUserId);

                              try {
                                await FirebaseFirestore.instance
                                    .runTransaction((transaction) async {
                                  final restSnapshot =
                                      await transaction.get(restRef);
                                  if (!restSnapshot.exists) return;

                                  final reviewSnapshot =
                                      await transaction.get(reviewRef);

                                  int currentCount =
                                      restSnapshot.data()?['ratingCount'] ?? 0;
                                  num currentSum =
                                      restSnapshot.data()?['ratingSum'] ?? 0;

                                  if (reviewSnapshot.exists) {
                                    num oldRating =
                                        reviewSnapshot.data()?['rating'] ?? 0;
                                    currentSum =
                                        currentSum - oldRating + currentRating;
                                  } else {
                                    currentCount += 1;
                                    currentSum += currentRating;
                                  }

                                  double newAvg = currentSum / currentCount;
                                  double roundedAvg = double.parse(
                                      newAvg.toStringAsFixed(1));

                                  transaction.update(restRef, {
                                    'ratingCount': currentCount,
                                    'ratingSum': currentSum,
                                    'avgRating': roundedAvg,
                                  });

                                  transaction.set(reviewRef, {
                                    'userId': currentUserId,
                                    'userName': userName,
                                    'rating': currentRating,
                                    'comment': comment,
                                    'imageUrl': imageUrl,
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });
                                });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'บันทึกคะแนนและรีวิวสำเร็จ ขอบคุณครับ!')));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง')));
                                }
                              }
                            },
                      child: isUploading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('ส่งรีวิว',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[50],
          foregroundColor: Colors.orange,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          Navigator.pop(context);
          _showRatingBottomSheet(context);
        },
        icon: const Icon(Icons.star_rate_rounded),
        label: const Text('ให้คะแนนร้านนี้',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}