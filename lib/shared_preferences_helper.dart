// shared_preferences_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static final SharedPreferencesHelper _instance = SharedPreferencesHelper._internal();
  
  factory SharedPreferencesHelper() {
    return _instance;
  }
  
  SharedPreferencesHelper._internal();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String?> getToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString("token");
  }

  Future<bool> setToken(String token) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.setString("token", token);
  }

  Future<String?> getName() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString("name");
  }

  Future<bool> setName(String name) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.setString("name", name);
  }

  Future<bool> removeToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.remove("token");
  }

  Future<bool> removeName() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.remove("name");
  }
}
