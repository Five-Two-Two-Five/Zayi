import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/insta_theme.dart';
import '../services/toast_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      if (_isLogin) {
        await authService.signIn(_emailController.text, _passwordController.text);
      } else {
        await authService.signUp(_emailController.text, _passwordController.text);
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(InstaPalette.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.cloud_sync,
                  size: 80,
                  color: InstaPalette.accent,
                ),
                const SizedBox(height: InstaPalette.spacingL),
                Text(
                  _isLogin ? 'Login to Zayi' : 'Create an Account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: InstaPalette.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: InstaPalette.spacingS),
                const Text(
                  'Sync your data across devices securely.',
                  style: TextStyle(
                    color: InstaPalette.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: InstaPalette.spacingXl),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      (value == null || !value.contains('@')) ? 'Invalid email' : null,
                ),
                const SizedBox(height: InstaPalette.spacingM),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      (value == null || value.length < 6) ? 'Password too short' : null,
                ),
                const SizedBox(height: InstaPalette.spacingL),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        child: Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
                const SizedBox(height: InstaPalette.spacingM),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Login',
                    style: const TextStyle(color: InstaPalette.accent),
                  ),
                ),
                if (_isLogin)
                TextButton(
                  onPressed: () {
                    // Navigate to main app without login
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Continue Offline',
                    style: TextStyle(color: InstaPalette.textSecondary),
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
