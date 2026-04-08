import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart';

class AddRestaurantPage extends StatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _openCtrl = TextEditingController();
  final _closeCtrl = TextEditingController();

  String _selectedCategory = 'food';
  final Set<String> _selectedFoodTypes = {};
  File? _selectedImage;
  geo.Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;

  static const Map<String, List<String>> _foodTypesByCategory = {
    'food': ['ก๋วยเตี๋ยว', 'ข้าวราดแกง', 'อาหารตามสั่ง', 'ส้มตำ', 'ยำ', 'เนื้อย่าง', 'ปิ้งย่าง', 'ผัดไทย', 'อาหารญี่ปุ่น'],
    'cafe': ['กาแฟ', 'ชา', 'เบเกอรี่', 'ชาไข่มุก', 'ชาผลไม้', 'ชานม', 'น้ำผลไม้', 'สมูทตี้', 'เครื่องดื่มสุขภาพ'],
    'drink': ['กาแฟ', 'ชา', 'เครื่องดื่ม', 'โยเกิร์ต', 'สมูทตี้'],
  };

  static const Map<String, String> _categoryLabels = {
    'food': 'ร้านอาหาร',
    'cafe': 'คาเฟ่',
    'drink': 'เครื่องดื่ม',
  };

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      }

      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('timeout'));

      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _isLoadingLocation = false;
      });
    } catch (_) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (!mounted) return;
    setState(() {
      _currentPosition = geo.Position(
        latitude: 13.8476,
        longitude: 100.5693,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _isLoadingLocation = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้รับตำแหน่ง GPS กรุณารอสักครู่')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      String? imageUrl;

      // Upload รูปปกร้าน (ถ้ามี)
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('pending_restaurants/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('pending_restaurants').add({
        'name': _nameCtrl.text.trim(),
        'desc': _descCtrl.text.trim(),
        'openTime': _openCtrl.text.trim(),
        'closeTime': _closeCtrl.text.trim(),
        'category': _selectedCategory,
        'foodTypes': _selectedFoodTypes.toList(),
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'imageUrl': imageUrl ?? '',
        'submittedBy': uid,
        'status': 'pending',
        'ratingCount': 0,
        'ratingSum': 0,
        'avgRating': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งคำขอเพิ่มร้านสำเร็จ! รอ Admin อนุมัติ')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodTypes = _foodTypesByCategory[_selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD54F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'เพิ่มร้านอาหาร',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== รูปปกร้าน =====
                        Center(
                          child: GestureDetector(
                            onTap: () => _showImageSourceDialog(),
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange.shade200, width: 1.5),
                                image: _selectedImage != null
                                    ? DecorationImage(
                                        image: FileImage(_selectedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _selectedImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            size: 48, color: Colors.orange.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'เพิ่มรูปปกร้าน (ไม่บังคับ)',
                                          style: TextStyle(color: Colors.orange.shade600),
                                        ),
                                      ],
                                    )
                                  : Align(
                                      alignment: Alignment.topRight,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedImage = null),
                                        child: Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ===== GPS Location Status =====
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isLoadingLocation
                                ? Colors.grey.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isLoadingLocation
                                  ? Colors.grey.shade300
                                  : Colors.green.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(Icons.location_on,
                                      color: Colors.green.shade600, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isLoadingLocation
                                      ? 'กำลังดึงตำแหน่ง GPS...'
                                      : 'ตำแหน่งพร้อมแล้ว: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isLoadingLocation
                                        ? Colors.grey
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ===== ชื่อร้าน =====
                        _buildLabel('ชื่อร้านอาหาร *'),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _inputDeco('เช่น ร้านข้าวต้มมดแดง'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อร้าน' : null,
                        ),
                        const SizedBox(height: 16),

                        // ===== คำอธิบาย =====
                        _buildLabel('คำอธิบายร้าน'),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: _inputDeco('อธิบายร้านของคุณ...'),
                        ),
                        const SizedBox(height: 16),

                        // ===== เวลาเปิด-ปิด =====
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('เวลาเปิด'),
                                  TextFormField(
                                    controller: _openCtrl,
                                    decoration: _inputDeco('08:00'),
                                    keyboardType: TextInputType.datetime,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('เวลาปิด'),
                                  TextFormField(
                                    controller: _closeCtrl,
                                    decoration: _inputDeco('22:00'),
                                    keyboardType: TextInputType.datetime,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ===== ประเภทร้าน (Category) =====
                        _buildLabel('ประเภทร้าน *'),
                        Row(
                          children: _categoryLabels.entries.map((e) {
                            final selected = _selectedCategory == e.key;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = e.key;
                                      _selectedFoodTypes.clear();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFE85B2A)
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFFE85B2A)
                                            : Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      e.value,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected ? Colors.white : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // ===== Food Type Tags =====
                        _buildLabel('Tag ประเภทอาหาร (เลือกได้หลายอย่าง)'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: foodTypes.map((ft) {
                            final selected = _selectedFoodTypes.contains(ft);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedFoodTypes.remove(ft);
                                  } else {
                                    _selectedFoodTypes.add(ft);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.orange.shade400
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.orange.shade400
                                        : Colors.orange.shade200,
                                  ),
                                ),
                                child: Text(
                                  ft,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selected
                                        ? Colors.white
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),

                        // ===== Submit Button =====
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE85B2A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed:
                                (_isSubmitting || _isLoadingLocation) ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'ส่งคำขอเพิ่มร้าน',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('เพิ่มรูปปกร้าน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('เลือกจาก Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
