import 'package:shared_preferences/shared_preferences.dart';

class AppStorageIOC {
  AppStorageIOC();

  Future<SharedPreferences> _getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.setString(key, value);
  }

  Future<String> getString(String key) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.getString(key) ?? '';
  }

  Future<bool> setBool(String key, bool value) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.setBool(key, value);
  }

  Future<bool> getBool(String key) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.getBool(key) ?? false;
  }

  Future<bool> remove(String key) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.remove(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.setStringList(key, value);
  }

  Future<bool> clear() async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.clear();
  }

  Future<bool> setInt(String key, int value) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.setInt(key, value);
  }

  Future<int> getInt(String key) async {
    final SharedPreferences prefs = await _getSharedPreferences();
    return prefs.getInt(key) ?? 0;
  }
}
