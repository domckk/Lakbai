import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _dio = buildDio();
  bool _loading = false, _obscure = true, _isRegister = false;
  final _usernameCtrl = TextEditingController();

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
      await _storage.write(key: 'access_token', value: res.data['accessToken']);
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

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: TrailColors.onSurfaceMuted),
        filled: true,
        fillColor: TrailColors.surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        labelStyle: TextStyle(color: TrailColors.onSurfaceMuted),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Image.asset('assets/images/logo.png', width: 120, errorBuilder: (_, __, ___) => const SizedBox()),
                ),
                const SizedBox(height: 16),
                Text('Lakbai', style: Theme.of(context).textTheme.displayMedium),
                Text(
                  _isRegister ? 'Create your account' : 'Welcome back, explorer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TrailColors.onSurfaceMuted),
                ),
                const SizedBox(height: 40),
                if (_isRegister) ...[
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: _dec('Username', Icons.person_outline),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => (v?.length ?? 0) < 3 ? 'Min 3 characters' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Email', Icons.email_outlined),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: _dec('Password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: TrailColors.onSurfaceMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v?.length ?? 0) < 8 ? 'Min 8 characters' : null,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isRegister ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister ? 'Already have an account? Sign in' : 'New here? Create account',
                      style: TextStyle(color: TrailColors.primary),
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
