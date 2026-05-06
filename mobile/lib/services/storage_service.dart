import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const int _tokenExpiryDays = 7;

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token methods
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
    // Salva a expiração: agora + 7 dias
    final expiryTime = DateTime.now()
        .add(const Duration(days: _tokenExpiryDays))
        .millisecondsSinceEpoch;
    await _prefs.setInt(_tokenExpiryKey, expiryTime);
  }

  String? getToken() {
    final token = _prefs.getString(_tokenKey);
    if (token != null && _isTokenExpired()) {
      // Token expirou, remove
      removeToken();
      return null;
    }
    return token;
  }

  Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_tokenExpiryKey);
  }

  bool hasToken() {
    return _prefs.containsKey(_tokenKey) && !_isTokenExpired();
  }

  bool _isTokenExpired() {
    final expiryTime = _prefs.getInt(_tokenExpiryKey);
    if (expiryTime == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiryTime;
  }

  // Retorna dias restantes
  int getTokenExpiryDaysRemaining() {
    final expiryTime = _prefs.getInt(_tokenExpiryKey);
    if (expiryTime == null) return 0;
    final remaining = DateTime.fromMillisecondsSinceEpoch(expiryTime)
        .difference(DateTime.now())
        .inDays;
    return remaining > 0 ? remaining : 0;
  }

  // User methods
  Future<void> saveUser(String userData) async {
    await _prefs.setString(_userKey, userData);
  }

  String? getUser() {
    return _prefs.getString(_userKey);
  }

  Future<void> removeUser() async {
    await _prefs.remove(_userKey);
  }

  // Logout - clear all
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
