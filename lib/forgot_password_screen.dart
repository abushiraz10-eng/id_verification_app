import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_screen.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5E9);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF888888);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _loading = false;
  bool _otpSent = false;
  bool _verifying = false;
  String _email = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ── Send OTP ──────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Please enter a valid email address');
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() {
        _email = email;
        _otpSent = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack('Error: $e');
    }
  }

  // ── Verify OTP ────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 8) {
      _snack('Please enter the 8-digit code');
      return;
    }
    setState(() => _verifying = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _email,
        token: otp,
        type: OtpType.recovery,
      );
      if (response.session != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          );
        }
      } else {
        _snack('Invalid code. Please try again.');
      }
    } catch (e) {
      _snack('Invalid or expired code. Please try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
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
                  const SizedBox(height: 32),

                  // Back button + title
                  Row(children: [
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
                        Text('Reset Password',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        Text('We will send a code to your email',
                            style: TextStyle(fontSize: 12, color: kGrey)),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 40),

                  // Show email step or OTP step
                  _otpSent ? _buildOtpStep() : _buildEmailStep(),

                  const SizedBox(height: 24),

                  if (!_otpSent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Remember your password? ',
                            style: TextStyle(color: kGrey, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign In',
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

  // ── Email Step ────────────────────────────
  Widget _buildEmailStep() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: kGreenLight, shape: BoxShape.circle),
              child:
                  const Icon(Icons.lock_reset_rounded, size: 40, color: kGreen),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter your email address and we will send you an 8-digit verification code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kGrey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text('Email Address',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ibnshiraz@yahoo.com',
              hintStyle: const TextStyle(color: kGrey, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.email_outlined, color: kGrey, size: 20),
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
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
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
                  : const Text('Send Code',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── OTP Step ──────────────────────────────
  Widget _buildOtpStep() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: kGreenLight, shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_read_rounded,
                  size: 40, color: kGreen),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'We sent an 8-digit code to $_email\n\nEnter the code below to continue.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kGrey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text('Verification Code',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 8,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '--------',
              hintStyle: TextStyle(
                  color: Colors.grey.shade300, fontSize: 22, letterSpacing: 8),
              counterText: '',
              filled: true,
              fillColor: kBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Did not receive it? ',
                  style: TextStyle(color: kGrey, fontSize: 13)),
              GestureDetector(
                onTap: () => setState(() {
                  _otpSent = false;
                  _otpCtrl.clear();
                }),
                child: const Text('Resend Code',
                    style: TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _verifying ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _verifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Verify Code',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
