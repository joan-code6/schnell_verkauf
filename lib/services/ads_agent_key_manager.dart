import 'package:shared_preferences/shared_preferences.dart';

class AdsAgentKeyManager {
  static const _prefsKey = 'kleinanzeigen_agent_api_key';
  static SharedPreferences? _prefs;

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<String?> getKey() async {
    await _init();
    return _prefs!.getString(_prefsKey);
  }

  static Future<bool> hasKey() async {
    return (await getKey())?.isNotEmpty == true;
  }

  static Future<void> saveKey(String key) async {
    await _init();
    await _prefs!.setString(_prefsKey, key.trim());
  }

  static Future<void> clearKey() async {
    await _init();
    await _prefs!.remove(_prefsKey);
  }
}