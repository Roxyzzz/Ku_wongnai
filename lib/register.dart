import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service/user_service.dart';
import 'main_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool loading = false;
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await UserService().registerUser(
        email: emailCtrl.text,
        password: passCtrl.text,
        name: nameCtrl.text,
        address: '', // ✅ ส่งค่าว่างไปแทน จะได้ไม่ต้องแก้โค้ดฝั่ง Backend
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างบัญชี + บันทึกข้อมูลสำเร็จ')),
      );

      // ✅ 2. เปลี่ยนให้เด้งไป MainPage แทน HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'อีเมลนี้ถูกใช้งานไปแล้ว',
        'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
        'weak-password' => 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร',
        _ => e.message ?? 'สมัครสมาชิกไม่สำเร็จ',
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFFF1C9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // ปรับให้กลืนกับพื้นหลังถ้าต้องการ
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: _inputDeco('ชื่อ-นามสกุล'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 16),

                // Email
                const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco('example@example.com'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'กรุณากรอกอีเมลให้ถูกต้อง' : null,
                ),
                const SizedBox(height: 16),

              
                const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passCtrl,
                  obscureText: _isPasswordHidden,
                  decoration: _inputDeco('อย่างน้อย 6 ตัวอักษร').copyWith(
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _isPasswordHidden = !_isPasswordHidden),
                      icon: Icon(
                        _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'รหัสผ่านต้องยาว 6 ตัวขึ้นไป' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  decoration: _inputDeco('ยืนยันรหัสผ่านอีกครั้ง'),
                  validator: (v) => v != passCtrl.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85B2A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: loading ? null : _register,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                      style: TextStyle(color: Color(0xFFE85B2A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}