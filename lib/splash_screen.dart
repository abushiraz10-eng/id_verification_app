import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

const kGreen = Color(0xFF1B6B3A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  bool _isPasswordRecovery = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Animations
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _controller.forward();

    // Listen for password recovery event IMMEDIATELY
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        _navigateTo(const ResetPasswordScreen());
      }
    });

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_navigated || !mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      if (_isPasswordRecovery) {
        _navigateTo(const ResetPasswordScreen());
      } else if (session != null) {
        _navigateTo(const DashboardScreen());
      } else {
        _navigateTo(const LoginScreen());
      }
    });
  }

  void _navigateTo(Widget screen) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreen,
      body: SafeArea(
        child: Stack(children: [
          // Background circles
          Positioned(
              top: -60,
              right: -60,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06)))),
          Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06)))),
          Positioned(
              top: 100,
              left: -40,
              child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10))
                            ],
                          ),
                          child: const Icon(Icons.verified_user_rounded,
                              size: 56, color: kGreen),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Verification System',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Tamale Technical University',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                letterSpacing: 1)),
                      ),
                      const SizedBox(height: 60),
                      _LoadingDots(),
                      const SizedBox(height: 20),
                      const Text('Securing your identity',
                          style:
                              TextStyle(fontSize: 13, color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) => Opacity(
                opacity: _fadeAnim.value,
                child: const Text('© 2026 TaTU Students Project',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final delay = i * 0.3;
          final progress = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final opacity =
              (0.3 + 0.7 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0));
          final scale =
              0.6 + 0.4 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                      opacity: opacity,
                      child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)))));
        }),
      ),
    );
  }
}
