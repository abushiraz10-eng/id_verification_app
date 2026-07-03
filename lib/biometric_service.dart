import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _emailKey = 'biometric_email';
  static const _passwordKey = 'biometric_password';
  static const _enabledKey = 'biometric_enabled';

  // ── Check if biometrics are available ──
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  // ── Check what biometrics are enrolled ──
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ── Authenticate with biometrics ──
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to sign in',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN as fallback
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Save credentials securely ──
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  // ── Get saved credentials ──
  Future<Map<String, String>?> getSavedCredentials() async {
    final enabled = await _storage.read(key: _enabledKey);
    if (enabled != 'true') return null;
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  // ── Check if biometric login is enabled ──
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _enabledKey);
    return enabled == 'true';
  }

  // ── Disable biometric login ──
  Future<void> disableBiometric() async {
    await _storage.deleteAll();
  }
}
