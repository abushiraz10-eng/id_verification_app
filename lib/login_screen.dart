import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'biometric_service.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5E9);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF888888);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthService();
  final _biometric = BiometricService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometric.isAvailable();
    final enabled = await _biometric.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
    // Auto-prompt fingerprint if enabled
    if (available && enabled) {
      _loginWithBiometric();
    }
  }

  // ── Login with email/password ──────────────
  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _snack('Please enter a valid email address');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }

    setState(() => _loading = true);
    final result = await _auth.login(email, password);
    setState(() => _loading = false);

    if (result == null) {
      // Save credentials for biometric login if available
      if (_biometricAvailable) {
        await _biometric.saveCredentials(email, password);
        setState(() => _biometricEnabled = true);
      }
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } else {
      _snack(result);
    }
  }

  // ── Login with biometric ──────────────────
  Future<void> _loginWithBiometric() async {
    final credentials = await _biometric.getSavedCredentials();
    if (credentials == null) {
      _snack('No saved credentials. Please log in with your password first.');
      return;
    }

    final authenticated = await _biometric.authenticate();
    if (!authenticated) return;

    setState(() => _loading = true);
    final result =
        await _auth.login(credentials['email']!, credentials['password']!);
    setState(() => _loading = false);

    if (result == null) {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } else {
      _snack('Biometric login failed. Please use your password.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
                  const SizedBox(height: 48),

                  // ── Logo ──
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        color: kGreen, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.verified_user_rounded,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 16),
                  const Text('Verification System',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kGreen)),
                  const SizedBox(height: 4),
                  const Text('Tamale Technical University',
                      style: TextStyle(fontSize: 13, color: kGrey)),

                  const SizedBox(height: 36),

                  // ── Card ──
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
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 4),
                        const Text('Sign in to continue',
                            style: TextStyle(fontSize: 13, color: kGrey)),

                        const SizedBox(height: 24),

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

                        const SizedBox(height: 10),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen())),
                            child: const Text('Forgot Password?',
                                style: TextStyle(
                                    color: kGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sign in button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
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
                                        color: Colors.white, strokeWidth: 2.5))
                                : const Text('Sign In',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(children: [
                          Expanded(child: Divider(color: Colors.grey.shade200)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade200)),
                        ]),

                        const SizedBox(height: 20),

                        // Fingerprint button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _biometricAvailable
                                ? _loginWithBiometric
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kGreen,
                              side: BorderSide(
                                color: _biometricAvailable
                                    ? kGreen
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fingerprint_rounded,
                                  size: 26,
                                  color: _biometricAvailable
                                      ? kGreen
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _biometricAvailable
                                      ? (_biometricEnabled
                                          ? 'Sign in with Fingerprint'
                                          : 'Enable Fingerprint Login')
                                      : 'Fingerprint Not Available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _biometricAvailable
                                        ? kGreen
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Biometric enabled indicator
                        if (_biometricEnabled) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 14, color: kGreen.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text('Fingerprint login is enabled',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: kGreen.withOpacity(0.7))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account? ',
                          style: TextStyle(color: kGrey, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: const Text('Register',
                            style: TextStyle(
                                color: kGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
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
