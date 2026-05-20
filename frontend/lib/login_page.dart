import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

// ─── Animated geometric background painter ────────────────────────────────────
class _GeoPainter extends CustomPainter {
  final double t;
  _GeoPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Slow-drifting rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final offsets = [
      Offset(w * 0.85, h * 0.12),
      Offset(w * 0.1, h * 0.75),
    ];
    final radii = [w * 0.55, w * 0.40];
    final colors = [
      const Color(0xFF6C63FF).withValues(alpha: 0.12),
      const Color(0xFF1D9E75).withValues(alpha: 0.09),
    ];

    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 4; j++) {
        final radius = radii[i] * (0.4 + j * 0.22) +
            math.sin(t * 0.8 + i * 1.5) * 6;
        ringPaint.color = colors[i];
        canvas.drawCircle(offsets[i], radius, ringPaint);
      }
    }

    // Diagonal accent lines (top-right corner)
    final linePaint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (int i = 0; i < 6; i++) {
      final x = w * 0.6 + i * 28.0;
      canvas.drawLine(
          Offset(x, 0), Offset(x + h * 0.3, h * 0.3), linePaint);
    }
  }

  @override
  bool shouldRepaint(_GeoPainter old) => old.t != t;
}

// ─── Subtle dot-grid painter ──────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9090A8).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Main LoginPage ────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoginSuccess});
  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  // Tab: 0 = sign in, 1 = sign up
  int _tab = 0;

  // Sign In
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Sign Up
  final _suNameCtrl = TextEditingController();
  final _suEmailCtrl = TextEditingController();
  final _suPassCtrl = TextEditingController();
  final _suConfirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureSuPass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _errorMsg = '';
  String _successMsg = '';

  late AnimationController _bgCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  final String _baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _slideAnim = CurvedAnimation(
        parent: _slideCtrl, curve: Curves.easeInOutCubic);
    _fadeAnim = CurvedAnimation(
        parent: _slideCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _suNameCtrl.dispose();
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
    if (tab == 1) {
      _slideCtrl.forward();
    } else {
      _slideCtrl.reverse();
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
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
        setState(() {
          _errorMsg =
              json.decode(res.body)['message'] ?? 'Invalid credentials.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Could not connect to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_suNameCtrl.text.trim().isEmpty ||
        _suEmailCtrl.text.trim().isEmpty ||
        _suPassCtrl.text.isEmpty ||
        _suConfirmCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields.');
      return;
    }
    if (_suPassCtrl.text != _suConfirmCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = '';
      _successMsg = '';
    });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _suNameCtrl.text.trim(),
          'email': _suEmailCtrl.text.trim(),
          'password': _suPassCtrl.text,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _successMsg = 'Account created! You can now sign in.';
          _errorMsg = '';
        });
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) _switchTab(0);
      } else {
        final body = json.decode(res.body);
        setState(() {
          _errorMsg = body['message'] ?? 'Registration failed.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Could not connect to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── UI helpers ─────────────────────────────────────────────────────────────

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
        border: Border.all(
            color: const Color(0xFF2A2A3E), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obsState ?? false,
        keyboardType: keyboard,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, letterSpacing: 0.3),
        onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555570), fontSize: 14),
          prefixIcon:
              Icon(icon, color: const Color(0xFF555570), size: 18),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    (obsState ?? false)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF555570),
                    size: 18,
                  ),
                  onPressed: toggleObs,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
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

  // ─── Sign In form ────────────────────────────────────────────────────────────
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
          toggleObs: () =>
              setState(() => _obscurePass = !_obscurePass),
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
            child: const Text('Forgot password?',
                style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 20),
        _buildSubmitButton('Sign In', _isLoading ? null : _login),
      ],
    );
  }

  // ─── Sign Up form ────────────────────────────────────────────────────────────
  Widget _buildSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          ctrl: _suNameCtrl,
          hint: 'Full name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
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
          toggleObs: () =>
              setState(() => _obscureSuPass = !_obscureSuPass),
        ),
        const SizedBox(height: 12),
        _buildField(
          ctrl: _suConfirmCtrl,
          hint: 'Confirm password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          obsState: _obscureConfirm,
          toggleObs: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onSubmit: _isLoading ? null : _signup,
        ),
        const SizedBox(height: 24),
        _buildSubmitButton(
            'Create Account', _isLoading ? null : _signup),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (ctx, _) {
          return Stack(
            children: [
              // Dot grid background
              CustomPaint(
                painter: _DotGridPainter(),
                size: MediaQuery.of(context).size,
              ),
              // Animated geometric rings
              CustomPaint(
                painter: _GeoPainter(_bgCtrl.value * 2 * math.pi),
                size: MediaQuery.of(context).size,
              ),

              // Top-left brand mark
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 28,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                            width: 1),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Color(0xFF6C63FF), size: 17),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Storefront',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Centered card
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 80,
                    24,
                    MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Column(
                    children: [
                      // ── Card container ──
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111120),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(0xFF1E1E32), width: 1),
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
                              // ── Heading ──
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Column(
                                  key: ValueKey(_tab),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _tab == 0
                                          ? 'Welcome back'
                                          : 'Create account',
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
                                      style: const TextStyle(
                                        color: Color(0xFF555570),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Pill tab switcher ──
                              Container(
                                height: 44,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E0E1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF1E1E32),
                                      width: 1),
                                ),
                                child: Stack(
                                  children: [
                                    // Sliding indicator
                                    AnimatedAlign(
                                      alignment: _tab == 0
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      duration: const Duration(
                                          milliseconds: 300),
                                      curve: Curves.easeInOutCubic,
                                      child: FractionallySizedBox(
                                        widthFactor: 0.5,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C63FF),
                                            borderRadius:
                                                BorderRadius.circular(9),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF6C63FF)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Labels
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _switchTab(0),
                                            child: Center(
                                              child: AnimatedDefaultTextStyle(
                                                duration: const Duration(
                                                    milliseconds: 250),
                                                style: TextStyle(
                                                  color: _tab == 0
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF555570),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                child:
                                                    const Text('Sign In'),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _switchTab(1),
                                            child: Center(
                                              child: AnimatedDefaultTextStyle(
                                                duration: const Duration(
                                                    milliseconds: 250),
                                                style: TextStyle(
                                                  color: _tab == 1
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF555570),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                child:
                                                    const Text('Sign Up'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Forms ──
                              AnimatedSize(
                                duration:
                                    const Duration(milliseconds: 350),
                                curve: Curves.easeInOutCubic,
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 320),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: Offset(
                                            _tab == 1 ? 0.06 : -0.06, 0),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                                  child: _tab == 0
                                      ? KeyedSubtree(
                                          key: const ValueKey('signin'),
                                          child: _buildSignIn(),
                                        )
                                      : KeyedSubtree(
                                          key: const ValueKey('signup'),
                                          child: _buildSignUp(),
                                        ),
                                ),
                              ),

                              // ── Messages ──
                              if (_errorMsg.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red
                                        .withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.red
                                            .withValues(alpha: 0.25),
                                        width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMsg,
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_successMsg.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D9E75)
                                        .withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFF1D9E75)
                                            .withValues(alpha: 0.3),
                                        width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          color: Color(0xFF1D9E75),
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _successMsg,
                                          style: const TextStyle(
                                              color: Color(0xFF1D9E75),
                                              fontSize: 12.5),
                                        ),
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

                      // ── Footer ──
                      Text(
                        '© ${DateTime.now().year} Storefront. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF333348), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}