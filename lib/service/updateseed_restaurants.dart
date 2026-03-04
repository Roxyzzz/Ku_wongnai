import 'package:cloud_firestore/cloud_firestore.dart';

String generateDocId(String name) {
  return name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^\u0E00-\u0E7Fa-z0-9]'), '');
}

// 🔥 ใส่พิกัดที่มี
final Map<String, ({double lat, double lng})> kuCoords = {
  "ม่าม่าพร": (lat: 13.844501062790398, lng: 100.56921213266581),
  "โรงอาหารกลาง 1 (บาร์ใหม่)": (lat: 13.848908754331225, lng: 100.56711001534337),
  "โรงอาหารกลาง 2 (บาร์ใหม่กว่า)": (lat: 13.852296736958907, lng: 100.57170066931322),
  "ศูนย์อาหารคณะวิทยาศาสตร์": (lat: 13.846278614814905, lng: 100.57131997301506),
  "โรงอาหารคณะบริหารธุรกิจ": (lat: 13.844613574370149, lng: 100.56869476931323),
  "โรงอาหารคณะสัตวแพทยศาสตร์": (lat: 13.844979510874493, lng: 100.5781424687473),
  "ศูนย์อาหารคณะวิศวกรรมศาสตร์": (lat: 13.846510702364734, lng: 100.56967348457005),
  "โรงอาหารคณะสถาปัตยกรรมศาสตร์": (lat: 13.853687078005052, lng: 100.56867362164104),
  "โรงอาหารคณะวนศาสตร์": (lat: 13.845906492905748, lng: 100.57312192594232),
  "MaxBeef Yakinikux": (lat: 13.84605541605602, lng: 100.56520768955991),
  "A.R.T. - Art of Coffee": (lat: 13.849171605884937, lng: 100.56728832436434),
  "เนสกาแฟ สตรีท คาเฟ่": (lat: 13.848688449651307, lng: 100.56668180674717),
  "Starbucks ตรงข้ามคณะบริหารฯ": (lat: 13.844560045764654, lng: 100.56886346072471),
  "Cafe Amazon สาขา อาคารพันธุ์ไม้": (lat: 13.84641639626245, lng: 100.56462544723033),
  "Inthanin Coffee KU": (lat: 13.847400133648271, lng: 100.56893849491453),
  "True Coffee KU": (lat: 13.843183435514186, lng: 100.5711444170066),
  "Bagbag Brew Coffee": (lat: 13.845266333834187, lng: 100.56944677791196),
  "SISKU COFFEE": (lat: 13.847284800209291, lng: 100.57036314907677),
  "Yoguruto ชั้น 1 อาคารวิศวกรรมสิ่งแวดล้อม": (lat: 13.84529222614992, lng: 100.56946413826171),
  "Chama - ชามะ ชาไข่มุกระเบิด": (lat: 13.846347715813677, lng: 100.56503682173987),
  "Beleaf & juice Shop": (lat: 13.846290087679805, lng: 100.56476691668414),
  "คณะเกษตร มหาวิทยาลัยเกษตรศาสตร์" : (lat: 13.849333453941474 , lng: 100.5720176638943),
};

Future<void> updateRestaurantLocations() async {
  final col = FirebaseFirestore.instance.collection('restaurants');

  for (final entry in kuCoords.entries) {
    final name = entry.key;
    final lat = entry.value.lat;
    final lng = entry.value.lng;

    final id = generateDocId(name);

    await col.doc(id).set({
      "latitude": lat,
      "longitude": lng,
      "location": GeoPoint(lat, lng),
      "googleMapsUrl":
          "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  print("✅ Locations updated safely");
}