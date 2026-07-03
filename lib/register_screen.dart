import 'package:flutter/material.dart';
import 'auth_service.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5E9);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF888888);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _adminCodeCtrl = TextEditingController();

  String _role = 'user';
  bool _loading = false;
  bool _obscurePassword = true;

  final _auth = AuthService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _adminCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty) {
      _snack('Please enter your full name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _snack('Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }

    setState(() => _loading = true);

    final result = await _auth.register(
      name,
      email,
      password,
      _role,
      _adminCodeCtrl.text.trim(),
    );

    setState(() => _loading = false);

    if (result == null) {
      if (mounted) {
        // Show success then go back to login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                      color: kGreenLight, shape: BoxShape.circle),
                  child: const Icon(Icons.mark_email_read_rounded,
                      color: kGreen, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('Account Created!',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'A verification email has been sent to your inbox. Please verify before logging in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kGrey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // back to login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Go to Login',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      _snack(result);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Header ────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6)
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.black87, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Account',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          Text('Fill in your details to register',
                              style: TextStyle(fontSize: 12, color: kGrey)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Form card ─────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        _label('Full Name'),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _nameCtrl,
                          hint: 'Ibn Shiraz',
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 16),

                        // Email
                        _label('Email Address'),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _emailCtrl,
                          hint: 'ibnshiraz@yahoo.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        // Password
                        _label('Password'),
                        const SizedBox(height: 6),
                        _inputField(
                          controller: _passwordCtrl,
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: kGrey,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Role selector
                        _label('Account Type'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: _roleCard(
                              label: 'User',
                              icon: Icons.person_rounded,
                              value: 'user',
                              subtitle: 'Submit & track IDs',
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _roleCard(
                              label: 'Admin',
                              icon: Icons.shield_rounded,
                              value: 'admin',
                              subtitle: 'Review & approve',
                            )),
                          ],
                        ),

                        // Admin code field — only shows if admin selected
                        if (_role == 'admin') ...[
                          const SizedBox(height: 16),
                          _label('Admin Code'),
                          const SizedBox(height: 6),
                          _inputField(
                            controller: _adminCodeCtrl,
                            hint: 'Enter GH_ADMIN',
                            icon: Icons.vpn_key_outlined,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Contact your system administrator for the admin code.',
                            style: TextStyle(fontSize: 11, color: kGrey),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text('Create Account',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(color: kGrey, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: kGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text('© TaTU Students Project',
                      style: TextStyle(color: kGrey, fontSize: 11)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Role selector card ──────────────────────
  Widget _roleCard({
    required String label,
    required IconData icon,
    required String value,
    required String subtitle,
  }) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? kGreenLight : kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kGreen : Colors.grey.shade200,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? kGreen : kGrey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selected ? kGreen : Colors.black87,
                      )),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 10, color: kGrey)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: kGreen, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87));
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kGrey, fontSize: 13),
        prefixIcon: Icon(icon, color: kGrey, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGreen, width: 1.5)),
      ),
    );
  }
}
