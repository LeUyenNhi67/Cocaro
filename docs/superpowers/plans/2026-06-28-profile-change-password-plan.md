# Profile & Change Password Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a profile screen containing a change password bottom sheet form and a logout option, integrated with Supabase auth.

**Architecture:** Add a new `ProfileScreen` widget and a custom `ChangePasswordBottomSheet` dialog. Replace the logout icon on `HomeScreen` with a profile icon. Re-authenticate user before updating password to enforce current password security.

**Tech Stack:** Flutter, Supabase Auth

## Global Constraints

- Must follow the existing cyberpunk/neon design (dark background, glowing orbs, glassmorphism).
- Use `NeonButton` for buttons.
- Password change requires current password validation, new password, and confirmation password.
- Validate new password has >= 6 characters.

---

### Task 1: Create Validator Utils & Write Unit Tests

**Files:**
- Create: `lib/utils/validators.dart`
- Create: `test/validators_test.dart`

**Interfaces:**
- Consumes: None
- Produces: `Validators.validatePassword(String?)`, `Validators.validateConfirmPassword(String?, String)`

- [ ] **Step 1: Write the failing tests**
  Create `test/validators_test.dart` with:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:co_caro/utils/validators.dart';

  void main() {
    group('Validators Test', () {
      test('Password validator works correctly', () {
        expect(Validators.validatePassword(null), 'Vui lòng nhập mật khẩu mới.');
        expect(Validators.validatePassword(''), 'Vui lòng nhập mật khẩu mới.');
        expect(Validators.validatePassword('12345'), 'Mật khẩu phải có ít nhất 6 ký tự.');
        expect(Validators.validatePassword('123456'), null);
      });

      test('Confirm Password validator works correctly', () {
        expect(Validators.validateConfirmPassword(null, '123456'), 'Vui lòng nhập lại mật khẩu mới.');
        expect(Validators.validateConfirmPassword('123', '123456'), 'Mật khẩu xác nhận không khớp.');
        expect(Validators.validateConfirmPassword('123456', '123456'), null);
      });
    });
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `flutter test test/validators_test.dart`
  Expected: Compile error because `validators.dart` does not exist yet.

- [ ] **Step 3: Write minimal implementation**
  Create `lib/utils/validators.dart` with:
  ```dart
  class Validators {
    static String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Vui lòng nhập mật khẩu mới.';
      }
      if (value.length < 6) {
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      }
      return null;
    }

    static String? validateConfirmPassword(String? value, String password) {
      if (value == null || value.isEmpty) {
        return 'Vui lòng nhập lại mật khẩu mới.';
      }
      if (value != password) {
        return 'Mật khẩu xác nhận không khớp.';
      }
      return null;
    }
  }
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `flutter test test/validators_test.dart`
  Expected: ALL TESTS PASSED

- [ ] **Step 5: Commit**
  Run: `git add lib/utils/validators.dart test/validators_test.dart; git commit -m "feat: add validators and tests"`

---

### Task 2: Update HomeScreen Navigation

**Files:**
- Modify: `lib/views/home_screen.dart`

**Interfaces:**
- Consumes: `ProfileScreen` (to be created in Task 3)
- Produces: Navigator transition to `ProfileScreen`

- [ ] **Step 1: Update import and AppBar actions in home_screen.dart**
  Open `lib/views/home_screen.dart` and modify lines 54-65.
  Change:
  ```dart
  // line 8 (add import)
  import 'profile_screen.dart';
  ```
  And change actions array:
  ```dart
        actions: [
          if (_isLoggedIn)
            IconButton(
              tooltip: 'Thông tin cá nhân',
              icon: const Icon(
                Icons.person_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
        ],
  ```

- [ ] **Step 2: Verify code compiling**
  Run: `flutter analyze`
  Expected: Error because `ProfileScreen` is not defined (to be resolved in Task 3).

- [ ] **Step 3: Commit**
  Run: `git add lib/views/home_screen.dart; git commit -m "feat: update HomeScreen header to navigate to profile"`

---

### Task 3: Create ProfileScreen

**Files:**
- Create: `lib/views/profile_screen.dart`

**Interfaces:**
- Consumes: `Supabase.instance.client.auth.currentUser`, `NeonButton`
- Produces: `ProfileScreen` widget

- [ ] **Step 1: Create the ProfileScreen file**
  Create `lib/views/profile_screen.dart` with:
  ```dart
  import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'widgets/neon_button.dart';
  import 'login_screen.dart';

  class ProfileScreen extends StatefulWidget {
    const ProfileScreen({Key? key}) : super(key: key);

    @override
    State<ProfileScreen> createState() => _ProfileScreenState();
  }

  class _ProfileScreenState extends State<ProfileScreen> {
    final _user = Supabase.instance.client.auth.currentUser;

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

    void _showChangePasswordBottomSheet(BuildContext context) {
      // Stub to be implemented in Task 4
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu sẽ được triển khai ở bước sau.')),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F2FE).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00F2FE).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF00F2FE),
                              size: 64,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
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
  ```

- [ ] **Step 2: Run analyze and verify compile succeeds**
  Run: `flutter analyze`
  Expected: No errors found.

- [ ] **Step 3: Commit**
  Run: `git add lib/views/profile_screen.dart; git commit -m "feat: add ProfileScreen base UI"`

---

### Task 4: Create ChangePasswordBottomSheet

**Files:**
- Create: `lib/views/widgets/change_password_bottom_sheet.dart`
- Modify: `lib/views/profile_screen.dart` (to display the bottom sheet)

**Interfaces:**
- Consumes: `Validators`, `Supabase.instance.client.auth`
- Produces: `ChangePasswordBottomSheet` widget, updates ProfileScreen password action.

- [ ] **Step 1: Create the ChangePasswordBottomSheet file**
  Create `lib/views/widgets/change_password_bottom_sheet.dart` with:
  ```dart
  import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import '../../utils/validators.dart';
  import 'neon_button.dart';

  class ChangePasswordBottomSheet extends StatefulWidget {
    const ChangePasswordBottomSheet({Key? key}) : super(key: key);

    @override
    State<ChangePasswordBottomSheet> createState() => _ChangePasswordBottomSheetState();
  }

  class _ChangePasswordBottomSheetState extends State<ChangePasswordBottomSheet> {
    final _formKey = GlobalKey<FormState>();
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmNewPasswordController = TextEditingController();
    
    bool _isLoading = false;
    String? _errorMessage;

    @override
    void dispose() {
      _currentPasswordController.dispose();
      _newPasswordController.dispose();
      _confirmNewPasswordController.dispose();
      super.dispose();
    }

    Future<void> _updatePassword() async {
      if (!_formKey.currentState!.validate()) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final auth = Supabase.instance.client.auth;
        final email = auth.currentUser?.email;
        if (email == null) throw Exception('Không tìm thấy thông tin email.');

        // Re-authenticate user to verify current password
        await auth.signInWithPassword(
          email: email,
          password: _currentPasswordController.text,
        );

        // Update to new password
        await auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );

        if (!mounted) return;
        Navigator.of(context).pop(); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = e.message == 'Invalid login credentials' 
              ? 'Mật khẩu hiện tại không chính xác.' 
              : e.message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ĐỔI MẬT KHẨU',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Current Password
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu hiện tại.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // Confirm New Password
                  TextFormField(
                    controller: _confirmNewPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      prefixIcon: Icon(Icons.lock_clock_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    validator: (v) => Validators.validateConfirmPassword(v, _newPasswordController.text),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFF6B9D), fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 32),
                  NeonButton(
                    text: _isLoading ? 'ĐANG CẬP NHẬT...' : 'CẬP NHẬT',
                    onPressed: _isLoading ? null : _updatePassword,
                    glowColor: const Color(0xFFFF007F),
                    gradientColors: const [Color(0xFFFF007F), Color(0xFFAA076B)],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Update ProfileScreen to show this bottom sheet**
  Modify `_showChangePasswordBottomSheet` in `lib/views/profile_screen.dart` to:
  ```dart
  // line 5 (add import)
  import 'widgets/change_password_bottom_sheet.dart';
  ```
  ```dart
    void _showChangePasswordBottomSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ChangePasswordBottomSheet(),
      );
    }
  ```

- [ ] **Step 3: Run analyze**
  Run: `flutter analyze`
  Expected: No errors found.

- [ ] **Step 4: Commit**
  Run: `git add lib/views/widgets/change_password_bottom_sheet.dart lib/views/profile_screen.dart; git commit -m "feat: implement change password bottom sheet UI and integration"`

---

## Verification Plan

### Automated Tests
- Run: `flutter test test/validators_test.dart`
  Expected: Output showing all password validator tests pass.

### Manual Verification
1. Open the application.
2. Sign in with a valid account.
3. Click the profile (User) icon in the top right of the `HomeScreen` AppBar.
4. Verify navigation to `ProfileScreen` works, user email is correctly displayed, and styling is consistent with neon/cyberpunk theme.
5. Tap "ĐỔI MẬT KHẨU". Verify that the modal bottom sheet appears with a blurred background, containing 3 inputs: Mật khẩu hiện tại, Mật khẩu mới, Xác nhận mật khẩu mới.
6. Try submitting empty fields to check field validations.
7. Fill incorrect current password, correct new password, and matching confirmation password. Submit and verify error message "Mật khẩu hiện tại không chính xác." is displayed.
8. Fill incorrect confirmation password. Verify validator displays "Mật khẩu xác nhận không khớp.".
9. Fill correct current password, valid new password, and matching confirmation password. Submit and verify that the sheet closes, a green success SnackBar "Đổi mật khẩu thành công!" is displayed.
10. Test sign out button on `ProfileScreen`. Verify that the user is logged out and returned to the `LoginScreen`.
