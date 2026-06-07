import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    return _isRegisterMode ? _signUp() : _signIn();
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _errorMessage = null;
      _successMessage = null;
      _confirmPasswordController.clear();
    });
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final nickname = _nicknameController.text.trim();
      final email = _emailController.text.trim();
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {'nickname': nickname},
      );

      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          _isRegisterMode = false;
          _successMessage =
              'Đăng ký thành công. Vui lòng kiểm tra email để xác nhận tài khoản.';
        });
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.grid_4x4_rounded,
                      size: 64,
                      color: Color(0xFF00F2FE),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isRegisterMode ? 'Đăng Ký' : 'Đăng Nhập',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegisterMode
                          ? 'Tạo tài khoản mới để vào game.'
                          : 'Sử dụng email và mật khẩu để vào game.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 32),
                    if (_isRegisterMode) ...[
                      TextFormField(
                        controller: _nicknameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.nickname],
                        decoration: const InputDecoration(
                          labelText: 'Nickname',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_isRegisterMode) return null;

                          final nickname = value?.trim() ?? '';
                          if (nickname.isEmpty) {
                            return 'Vui lòng nhập nickname.';
                          }
                          if (nickname.length < 3) {
                            return 'Nickname phải có ít nhất 3 ký tự.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Vui lòng nhập email.';
                        if (!email.contains('@')) return 'Email không hợp lệ.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: _isRegisterMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) {
                        if (!_isRegisterMode) _submit();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu.';
                        }
                        if (_isRegisterMode && value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự.';
                        }
                        return null;
                      },
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_isRegisterMode) return null;
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập lại mật khẩu.';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu xác nhận không khớp.';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFF6B9D)),
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _successMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF22C55E)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isRegisterMode
                                  ? Icons.person_add_alt_1_rounded
                                  : Icons.login_rounded,
                            ),
                      label: Text(
                        _isLoading
                            ? (_isRegisterMode
                                  ? 'Đang đăng ký...'
                                  : 'Đang đăng nhập...')
                            : (_isRegisterMode ? 'Đăng Ký' : 'Đăng Nhập'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isRegisterMode
                            ? 'Đã có tài khoản? Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
