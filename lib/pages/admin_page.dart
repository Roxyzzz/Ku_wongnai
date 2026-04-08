import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ku_wongnai/widgets/storage_image_widget.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Future<void> _approveRestaurant(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    try {
      // copy ไป collection 'restaurants'
      await FirebaseFirestore.instance.collection('restaurants').add(data);
      // ลบจาก pending
      await FirebaseFirestore.instance
          .collection('pending_restaurants')
          .doc(docId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ อนุมัติร้านสำเร็จ!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _rejectRestaurant(BuildContext context, String docId) async {
    // แสดง confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการปฏิเสธ'),
        content: const Text('คุณต้องการปฏิเสธร้านนี้? ข้อมูลจะถูกลบออกจากระบบ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ปฏิเสธ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('pending_restaurants')
          .doc(docId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ ปฏิเสธร้านแล้ว')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD54F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Admin Panel',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.pending_actions,
                                color: Colors.orange.shade700, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ร้านที่รอการอนุมัติ',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('pending_restaurants')
                            .where('status', isEqualTo: 'pending')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                          }

                          final docs = snapshot.data?.docs ?? [];
                          // เรียงจากใหม่ไปเก่า (client-side)
                          final sorted = [...docs]..sort((a, b) {
                              final aTime = (a.data() as Map)['createdAt'];
                              final bTime = (b.data() as Map)['createdAt'];
                              if (aTime == null || bTime == null) return 0;
                              return (bTime as dynamic).compareTo(aTime);
                            });

                          if (sorted.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 64, color: Colors.green.shade300),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'ไม่มีร้านที่รอการอนุมัติ',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: sorted.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final doc = sorted[index];
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              final String name =
                                  data['name'] ?? 'ไม่มีชื่อร้าน';
                              final String desc = data['desc'] ?? '';
                              final String? imagePath =
                                  data['imagePath'] as String?;
                              final hasImage = imagePath != null && imagePath.isNotEmpty;
                              final String category =
                                  data['category'] ?? '';
                              final List foodTypes =
                                  data['foodTypes'] ?? [];
                              final double lat =
                                  (data['latitude'] as num?)?.toDouble() ??
                                      0;
                              final double lng =
                                  (data['longitude'] as num?)?.toDouble() ??
                                      0;
                              final String openTime =
                                  data['openTime'] ?? '-';
                              final String closeTime =
                                  data['closeTime'] ?? '-';

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.orange.shade100),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // รูปภาพร้าน (Firebase Storage)
                                    if (hasImage)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                        child: StorageImageWidget(
                                          storagePath: imagePath,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius:
                                              const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.restaurant,
                                              size: 40,
                                              color: Colors.orange.shade200),
                                        ),
                                      ),

                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // ชื่อ + category badge
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Colors.orange.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .orange.shade800,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              desc,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          // เวลา
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 14,
                                                  color: Colors.orange),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$openTime - $closeTime',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.location_on,
                                                  size: 14,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          // food type tags
                                          if (foodTypes.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: foodTypes
                                                  .map((t) => Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .orange.shade50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                              color: Colors
                                                                  .orange
                                                                  .shade200),
                                                        ),
                                                        child: Text(
                                                          t.toString(),
                                                          style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .orange
                                                                  .shade700),
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                          ],
                                          const SizedBox(height: 14),
                                          // ปุ่ม Approve / Reject
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(
                                                        color: Colors.red),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _rejectRestaurant(
                                                          context, doc.id),
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.red,
                                                      size: 18),
                                                  label: const Text(
                                                    'ปฏิเสธ',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    // ลบ field 'status','submittedBy' ที่ไม่ควรอยู่ใน restaurant collection
                                                    final cleanData =
                                                        Map<String,
                                                                dynamic>.from(
                                                            data)
                                                          ..remove('status')
                                                          ..remove(
                                                              'submittedBy');
                                                    _approveRestaurant(context,
                                                        doc.id, cleanData);
                                                  },
                                                  icon: const Icon(Icons.check,
                                                      color: Colors.white,
                                                      size: 18),
                                                  label: const Text(
                                                    'อนุมัติ',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
