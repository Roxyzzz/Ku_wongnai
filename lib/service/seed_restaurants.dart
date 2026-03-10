import 'package:cloud_firestore/cloud_firestore.dart';

final List<Map<String, dynamic>> kuRestaurants = [
  {
    "name": "A.R.T. - Art of Coffee",
    "desc": "คาเฟ่กาแฟพิเศษ บรรยากาศชิลใต้ตึก",
    "category": "cafe",
    "imageUrl": "https://img.wongnai.com/p/800x0/2020/06/17/3d8b584a2f8c4b128c707f18544062c9.jpg",
    "address": "มหาวิทยาลัยเกษตรศาสตร์ บางเขน",
    "openTime": "07:00",
    "closeTime": "16:00",
    "avgRating": 5.0,
    "ratingCount": 1,
    "ratingSum": 5,
    "latitude": 13.849171605884937,
    "longitude": 100.56728832436434,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "name": "โรงอาหารกลาง 1 (บาร์ใหม่)",
    "desc": "โรงอาหารยอดนิยม ร้านอาหารหลากหลาย ราคานักศึกษา",
    "category": "food",
    "imageUrl": "https://p-u.poprebel.com/img/places/15/15740/15740_1.jpg",
    "address": "มหาวิทยาลัยเกษตรศาสตร์ บางเขน",
    "openTime": "06:00",
    "closeTime": "21:00",
    "avgRating": 0,
    "latitude": 13.848908754331225,
    "longitude": 100.56711001534337,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "name": "โรงอาหารกลาง 2 (บาร์ใหม่กว่า)",
    "desc": "โรงอาหารขนาดใหญ่ ทันสมัย ใกล้คณะวิศวะ",
    "category": "food",
    "imageUrl": "https://img.wongnai.com/p/1920x0/2017/09/25/676f2796e6804791a8e99999086f0c33.jpg",
    "address": "มหาวิทยาลัยเกษตรศาสตร์ บางเขน",
    "openTime": "06:00",
    "closeTime": "15:30",
    "avgRating": 0,
    "latitude": 13.852296736958907,
    "longitude": 100.57170066931322,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "name": "Cafe Amazon สาขา อาคารพันธุ์ไม้",
    "desc": "กาแฟมาตรฐานอเมซอน บรรยากาศร่มรื่น",
    "category": "cafe",
    "imageUrl": "https://img.wongnai.com/p/800x0/2019/08/13/46c03975003c40339d10e060011505d5.jpg",
    "address": "มหาวิทยาลัยเกษตรศาสตร์ บางเขน",
    "openTime": "07:00",
    "closeTime": "17:00",
    "avgRating": 0,
    "latitude": 13.84641639626245,
    "longitude": 100.56462544723033,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "name": "MaxBeef Yakiniku",
    "desc": "เนื้อย่างพรีเมียมราคาย่อมเยา สไตล์เด็กเกษตร",
    "category": "food",
    "imageUrl": "https://img.wongnai.com/p/800x0/2018/06/18/6959146f325d488e9949f57989582845.jpg",
    "address": "มหาวิทยาลัยเกษตรศาสตร์ บางเขน",
    "openTime": "10:00",
    "closeTime": "19:00",
    "avgRating": 0,
    "latitude": 13.84605541605602,
    "longitude": 100.56520768955991,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "name": "Yoguruto วิศวะเกษตร",
    "desc": "โยเกิร์ตสดปั่นสไตล์ญี่ปุ่น ยอดฮิตของชาววิศวะ",
    "category": "cafe",
    "imageUrl": "https://img.wongnai.com/p/800x0/2021/04/14/b421a249f0564619934252658e390c50.jpg",
    "address": "มหาวิทยาลัยเกษตรศาสตร์ บางเขน",
    "openTime": "09:00",
    "closeTime": "17:30",
    "avgRating": 0,
    "latitude": 13.84529222614992,
    "longitude": 100.56946413826171,
    "createdAt": FieldValue.serverTimestamp(),
  },
  {
    "name": "ม่าม่าพร",
    "desc": "ยำมาม่าในตำนาน เครื่องแน่น รสจัดจ้าน",
    "category": "food",
    "imageUrl": "https://img.wongnai.com/p/800x0/2016/06/14/d602330f8f874220800726d405903790.jpg",
    "address": "มหาวิทยาลัยเกษตรศาสตร์ บางเขน",
    "openTime": "08:00",
    "closeTime": "17:00",
    "avgRating": 0,
    "latitude": 13.844501062790398,
    "longitude": 100.56921213266581,
    "createdAt": FieldValue.serverTimestamp(),
  }
];

String generateDocId(String name) {
  return name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^\u0E00-\u0E7Fa-z0-9]'), '');
}

Future<void> seedRestaurants() async {
  final col = FirebaseFirestore.instance.collection('restaurants');

  for (final r in kuRestaurants) {
    final name = r['name'] as String;
    if (name.isEmpty) continue; 
    
    final id = generateDocId(name);
    final docSnapshot = await col.doc(id).get();

    if (docSnapshot.exists) {
      final Map<String, dynamic> updateData = {
        "name": r['name'],
        "desc": r['desc'],
        "category": r['category'],
        "address": r['address'],
        "openTime": r['openTime'],
        "closeTime": r['closeTime'],
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if ((r['imageUrl'] as String).isNotEmpty) {
        updateData['imageUrl'] = r['imageUrl'];
      }

      await col.doc(id).update(updateData);
    } else {
      final newData = {
        ...r,
        "latitude": r['latitude'],
        "longitude": r['longitude'],
        "location": null,
        "googleMapsUrl": r['googleMapsUrl'],
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await col.doc(id).set(newData);
    }
  }

  print("✅ Restaurants collection updated successfully with stable links");
}