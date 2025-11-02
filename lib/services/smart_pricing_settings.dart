import 'package:shared_preferences/shared_preferences.dart';

class SmartPricingSettings {
  static const _key = 'smart_pricing_enabled';
  static SharedPreferences? _prefs;

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> isEnabled() async {
    await _init();
    return _prefs!.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    await _init();
    await _prefs!.setBool(_key, value);
  }
}
