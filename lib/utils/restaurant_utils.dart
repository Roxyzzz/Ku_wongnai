import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// คำนวณว่าร้านเปิดอยู่หรือเปล่า ณ เวลาปัจจุบัน
bool isOpenNow(dynamic openTime, dynamic closeTime) {
  if (openTime == null || closeTime == null) return false;
  try {
    // normalize "07.00" → "07:00"
    final open = openTime.toString().replaceAll('.', ':');
    final close = closeTime.toString().replaceAll('.', ':');

    final openParts = open.split(':');
    final closeParts = close.split(':');

    if (openParts.length < 2 || closeParts.length < 2) return false;

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

    // รองรับร้านที่เปิดข้ามคืน (เช่น 22:00 - 02:00)
    if (closeMin < openMin) {
      return nowMin >= openMin || nowMin < closeMin;
    }
    return nowMin >= openMin && nowMin < closeMin;
  } catch (_) {
    return false;
  }
}

/// Widget badge แสดงสถานะ เปิด/ปิด
class OpenStatusBadge extends StatelessWidget {
  final dynamic openTime;
  final dynamic closeTime;
  final bool small;

  const OpenStatusBadge({
    super.key,
    required this.openTime,
    required this.closeTime,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final open = isOpenNow(openTime, closeTime);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: open ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: open ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 5 : 6,
            height: small ? 5 : 6,
            decoration: BoxDecoration(
              color: open ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: small ? 3 : 4),
          Text(
            open ? 'เปิดอยู่' : 'ปิดแล้ว',
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: open ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// สร้าง PNG ของ "จุดสีน้ำเงิน" สำหรับ current location marker บน Mapbox
Future<Uint8List> generateLocationMarkerPng({int size = 80}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 4;

  // วงกลมขาว (เส้นขอบ)
  canvas.drawCircle(center, radius + 4, Paint()..color = const ui.Color(0xFFFFFFFF));
  // วงกลมน้ำเงิน
  canvas.drawCircle(center, radius, Paint()..color = const ui.Color(0xFF2196F3));
  // วงกลมขาวตรงกลาง (dot กลาง)
  canvas.drawCircle(center, radius * 0.35, Paint()..color = const ui.Color(0xFFFFFFFF));

  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
