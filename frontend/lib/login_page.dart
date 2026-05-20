import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoginSuccess});
  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  int _tab = 0;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _suEmailCtrl = TextEditingController();
  final _suPassCtrl = TextEditingController();
  final _suConfirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureSuPass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _errorMsg = '';
  String _successMsg = '';

  final String _baseUrl = 'http://localhost:3000';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _suEmailCtrl.dispose();
    _suPassCtrl.dispose();
    _suConfirmCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _errorMsg = '';
      _successMsg = '';
    });
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields.');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = ''; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        widget.onLoginSuccess();
      } else {
        setState(() => _errorMsg = json.decode(res.body)['message'] ?? 'Invalid credentials.');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Could not connect to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_suEmailCtrl.text.trim().isEmpty || _suPassCtrl.text.isEmpty || _suConfirmCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields.');
      return;
    }
    if (_suPassCtrl.text != _suConfirmCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = ''; _successMsg = ''; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _suEmailCtrl.text.trim(),
          'password': _suPassCtrl.text,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() { _successMsg = 'Account created! You can now sign in.'; _errorMsg = ''; });
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) _switchTab(0);
      } else {
        setState(() => _errorMsg = json.decode(res.body)['message'] ?? 'Registration failed.');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Could not connect to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool? obsState,
    VoidCallback? toggleObs,
    TextInputType keyboard = TextInputType.text,
    VoidCallback? onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3E), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obsState ?? false,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 0.3),
        onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555570), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF555570), size: 18),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    (obsState ?? false) ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF555570),
                    size: 18,
                  ),
                  onPressed: toggleObs,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF8B84FF), Color(0xFF6C63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: onTap == null ? const Color(0xFF2A2A3E) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          ctrl: _emailCtrl,
          hint: 'Email address',
          icon: Icons.mail_outline_rounded,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildField(
          ctrl: _passCtrl,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          obsState: _obscurePass,
          toggleObs: () => setState(() => _obscurePass = !_obscurePass),
          onSubmit: _isLoading ? null : _login,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6C63FF),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 20),
        _buildSubmitButton('Sign In', _isLoading ? null : _login),
      ],
    );
  }

  Widget _buildSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          ctrl: _suEmailCtrl,
          hint: 'Email address',
          icon: Icons.mail_outline_rounded,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildField(
          ctrl: _suPassCtrl,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          obsState: _obscureSuPass,
          toggleObs: () => setState(() => _obscureSuPass = !_obscureSuPass),
        ),
        const SizedBox(height: 12),
        _buildField(
          ctrl: _suConfirmCtrl,
          hint: 'Confirm password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          obsState: _obscureConfirm,
          toggleObs: () => setState(() => _obscureConfirm = !_obscureConfirm),
          onSubmit: _isLoading ? null : _signup,
        ),
        const SizedBox(height: 24),
        _buildSubmitButton('Create Account', _isLoading ? null : _signup),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 40,
            24,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF6C63FF), size: 26),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF111120),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1E1E32), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey(_tab),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tab == 0 ? 'Welcome back' : 'Create account',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tab == 0
                                  ? 'Sign in to manage your inventory.'
                                  : 'Join us and start selling today.',
                              style: const TextStyle(color: Color(0xFF555570), fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E0E1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E1E32), width: 1),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              alignment: _tab == 0 ? Alignment.centerLeft : Alignment.centerRight,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                heightFactor: 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF),
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _switchTab(0),
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 250),
                                          style: TextStyle(
                                            color: _tab == 0 ? Colors.white : const Color(0xFF555570),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          child: const Text('Sign In'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _switchTab(1),
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 250),
                                          style: TextStyle(
                                            color: _tab == 1 ? Colors.white : const Color(0xFF555570),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          child: const Text('Sign Up'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(_tab == 1 ? 0.06 : -0.06, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _tab == 0
                              ? KeyedSubtree(key: const ValueKey('signin'), child: _buildSignIn())
                              : KeyedSubtree(key: const ValueKey('signup'), child: _buildSignUp()),
                        ),
                      ),

                      if (_errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMsg,
                                    style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_successMsg.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D9E75).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF1D9E75).withValues(alpha: 0.3), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Color(0xFF1D9E75), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_successMsg,
                                    style: const TextStyle(
                                        color: Color(0xFF1D9E75), fontSize: 12.5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              Text(
                '© ${DateTime.now().year} Storefront. All rights reserved.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF333348), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}