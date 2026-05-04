import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _storage      = const FlutterSecureStorage();
  final _dio          = buildDio();
  bool _loading = false, _obscure = true, _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final endpoint = _isRegister ? '/auth/register' : '/auth/login';
      final body = _isRegister
          ? {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text, 'username': _usernameCtrl.text.trim()}
          : {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text};
      final res = await _dio.post(endpoint, data: body);
      await _storage.write(key: 'access_token',  value: res.data['accessToken']);
      await _storage.write(key: 'refresh_token', value: res.data['refreshToken']);
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Logo + brand
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                const SizedBox(height: 40),

                // Heading
                Text(
                  _isRegister ? 'Create your account' : 'Welcome back, explorer',
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: TrailColors.onBackground,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),
                Text(
                  _isRegister ? 'Join and start your trail journey' : 'Sign in to continue your adventure',
                  style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 14),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 32),

                // Fields
                if (_isRegister) ...[
                  TextFormField(
                    controller: _usernameCtrl,
                    style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v?.length ?? 0) < 3 ? 'Min 3 characters' : null,
                  ).animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      color: TrailColors.onSurfaceMuted,
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v?.length ?? 0) < 8 ? 'Min 8 characters' : null,
                ).animate().fadeIn(delay: 220.ms),

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_isRegister ? 'Create Account' : 'Sign In'),
                ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.2),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister ? 'Already have an account? Sign in' : 'New here? Create account',
                      style: const TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
