import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5E9);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF888888);

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _passwordReset = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (password.isEmpty || password.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _passwordReset = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Error: ${e.toString()}');
      }
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
              child: Column(children: [
                const SizedBox(height: 48),

                // Logo
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
                const Text('Tamale Technical University (TaTU)',
                    style: TextStyle(fontSize: 13, color: kGrey)),
                const SizedBox(height: 36),

                // Success or form
                if (_passwordReset) _buildSuccess() else _buildForm(),

                const SizedBox(height: 20),
                const Text('© 2026 TaTU Students Project',
                    style: TextStyle(color: kGrey, fontSize: 11)),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Set New Password',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 4),
        const Text('Choose a strong password for your account',
            style: TextStyle(fontSize: 13, color: kGrey)),
        const SizedBox(height: 24),

        // New password
        _label('New Password'),
        const SizedBox(height: 6),
        _field(
            ctrl: _passwordCtrl,
            hint: '••••••••',
            obscure: _obscurePassword,
            toggle: () => setState(() => _obscurePassword = !_obscurePassword)),
        const SizedBox(height: 16),

        // Confirm password
        _label('Confirm New Password'),
        const SizedBox(height: 6),
        _field(
            ctrl: _confirmCtrl,
            hint: '••••••••',
            obscure: _obscureConfirm,
            toggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
        const SizedBox(height: 12),

        // Hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: kGreenLight, borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: kGreen, size: 16),
            SizedBox(width: 8),
            Text('Password must be at least 6 characters',
                style: TextStyle(color: kGreen, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _updatePassword,
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
                : const Text('Update Password',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration:
              const BoxDecoration(color: kGreenLight, shape: BoxShape.circle),
          child:
              const Icon(Icons.check_circle_rounded, size: 44, color: kGreen),
        ),
        const SizedBox(height: 20),
        const Text('Password Updated!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text(
          'Your password has been successfully updated. You can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kGrey, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kGrey, fontSize: 13),
        prefixIcon:
            const Icon(Icons.lock_outline_rounded, color: kGrey, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: kGrey,
              size: 20),
          onPressed: toggle,
        ),
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
