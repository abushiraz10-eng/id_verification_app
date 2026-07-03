import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'reset_password_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _isPasswordRecovery = true);
      }
      if (data.event == AuthChangeEvent.signedOut) {
        setState(() => _isPasswordRecovery = false);
      }
      if (data.event == AuthChangeEvent.signedIn && !_isPasswordRecovery) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isPasswordRecovery) return const ResetPasswordScreen();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return const DashboardScreen();
    return const LoginScreen();
  }
}
