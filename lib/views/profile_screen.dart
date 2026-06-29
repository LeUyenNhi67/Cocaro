import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/change_password_bottom_sheet.dart';
import 'widgets/neon_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  late final TextEditingController _nicknameController;
  String? _avatarBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final metadata = _user?.userMetadata;
    final initialNickname = metadata?['nickname'] as String? ?? '';
    _nicknameController = TextEditingController(text: initialNickname);
    _avatarBase64 = metadata?['avatar_base64'] as String?;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng xuất thất bại. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _pickAndSaveAvatar() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_base64': base64Image}),
      );

      setState(() {
        _avatarBase64 = base64Image;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ảnh đại diện thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật ảnh đại diện: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNickname() async {
    final newName = _nicknameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'nickname': newName}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu biệt danh thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật biệt danh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAmbientOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAvatarWidget() {
    ImageProvider? imageProvider;
    if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(_avatarBase64!));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: _isLoading ? null : _pickAndSaveAvatar,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00F2FE),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: imageProvider != null
                  ? Image(image: imageProvider, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF00F2FE).withOpacity(0.1),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF00F2FE),
                        size: 56,
                      ),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFF007F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? 'Chưa đăng nhập';

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'THÔNG TIN CÁ NHÂN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _buildAmbientOrb(const Color(0xFF00F2FE), 250),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _buildAmbientOrb(const Color(0xFFFF007F), 250),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glassmorphic User Profile Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildAvatarWidget(),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nicknameController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'BIỆT DANH / NICKNAME',
                            labelStyle: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF00F2FE),
                              ),
                              onPressed: _isLoading ? null : _saveNickname,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00F2FE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Email tài khoản',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  NeonButton(
                    text: 'ĐỔI MẬT KHẨU',
                    icon: Icons.lock_outline_rounded,
                    glowColor: const Color(0xFF00F2FE),
                    gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    onPressed: () => _showChangePasswordBottomSheet(context),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text(
                      'ĐĂNG XUẤT',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
