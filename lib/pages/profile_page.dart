import 'dart:io';
import 'package:ku_wongnai/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController newPasswordCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;
  bool isSaving = false;
  bool isChangingPassword = false;
  bool obscurePassword = true;

  String email = '';
  String photoPath = '';
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  String _nameKey(String uid) => 'profile_name_$uid';
  String _addressKey(String uid) => 'profile_address_$uid';
  String _photoKey(String uid) => 'profile_photo_$uid';

  Future<void> loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      email = user.email ?? '';

      final prefs = await SharedPreferences.getInstance();

      nameCtrl.text = prefs.getString(_nameKey(user.uid)) ?? '';
      addressCtrl.text = prefs.getString(_addressKey(user.uid)) ?? '';

      final savedPhotoPath = prefs.getString(_photoKey(user.uid)) ?? '';

      if (savedPhotoPath.isNotEmpty && File(savedPhotoPath).existsSync()) {
        photoPath = savedPhotoPath;
      } else {
        photoPath = '';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      setState(() {
        selectedImage = File(pickedFile.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เลือกรูปไม่สำเร็จ: $e')));
    }
  }

  Future<String?> saveProfileImageLocally() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (selectedImage == null) return photoPath;

      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile_images');

      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final newPath = '${profileDir.path}/${user.uid}.jpg';
      final savedFile = await selectedImage!.copy(newPath);

      return savedFile.path;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกรูปในเครื่องไม่สำเร็จ: $e')));
      return null;
    }
  }

  Future<void> saveProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      setState(() => isSaving = true);

      final prefs = await SharedPreferences.getInstance();

      String finalPhotoPath = photoPath;

      if (selectedImage != null) {
        final localPath = await saveProfileImageLocally();
        if (localPath == null) {
          setState(() => isSaving = false);
          return;
        }
        finalPhotoPath = localPath;
      }

      await prefs.setString(_nameKey(user.uid), nameCtrl.text.trim());
      await prefs.setString(_addressKey(user.uid), addressCtrl.text.trim());
      await prefs.setString(_photoKey(user.uid), finalPhotoPath);

      setState(() {
        photoPath = finalPhotoPath;
        selectedImage = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์สำเร็จ!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกโปรไฟล์ไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> changePassword() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String newPassword = newPasswordCtrl.text.trim();

      if (newPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกรหัสผ่านใหม่')),
        );
        return;
      }

      if (newPassword.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร')),
        );
        return;
      }

      setState(() => isChangingPassword = true);

      await user.updatePassword(newPassword);
      newPasswordCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เปลี่ยนรหัสผ่านไม่สำเร็จ: $e\n(อาจต้องออกจากระบบแล้วเข้าใหม่)',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isChangingPassword = false);
    }
  }

  Future<void> logout() async {
  await FirebaseAuth.instance.signOut();
  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (Route<dynamic> route) => false,
    );
    }
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildEmailBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            email,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  ImageProvider? getProfileImage() {
    if (selectedImage != null) return FileImage(selectedImage!);

    if (photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    return null;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = getProfileImage();

    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD54F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Settings & Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImage,
                            child: profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE85B2A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    buildTextField(label: 'ชื่อ-นามสกุล', controller: nameCtrl),
                    buildEmailBox(),
                    buildTextField(label: 'ที่อยู่', controller: addressCtrl),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE85B2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'บันทึกข้อมูลส่วนตัว',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(color: Colors.black12, thickness: 1),
                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'เปลี่ยนรหัสผ่าน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    buildTextField(
                      label: 'รหัสผ่านใหม่',
                      controller: newPasswordCtrl,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isChangingPassword ? null : changePassword,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFE85B2A),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isChangingPassword
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE85B2A),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'อัปเดตรหัสผ่าน',
                                style: TextStyle(
                                  color: Color(0xFFE85B2A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}