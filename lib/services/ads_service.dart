import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Manages ad visibility based on a remote GitHub Gist + local family code.
///
/// Gist JSON format example (ads_control.json):
/// {
///   "ads_enabled": true,
///   "codes": {
///     "ABC123": 1,
///     "XYZ789": 3
///   }
/// }
/// - ads_enabled: if false -> hide ads for everyone globally.
/// - codes: map of code -> months of ad-free (integer months)
///
/// Local flow:
/// 1. User enters a family code (stored locally).
/// 2. First validation stores activation timestamp + months.
/// 3. Ad-free until activation + months*30 days (simplified month length).
class AdsService {
  static const _prefsCodeKey = 'family_ad_code';
  static const _prefsCodeActivatedKey = 'family_ad_code_activated';
  static const _prefsCodeMonthsKey = 'family_ad_code_months';

  /// Raw gist URL (without pinned commit so updates propagate)
  /// e.g. https://gist.githubusercontent.com/<user>/<gist-id>/raw/ads_control.json
  static String gistRawUrl = 'https://gist.githubusercontent.com/joan-code6/322388e07b25d512fafec2d8b65f7e41/raw/ads_control.json';

  static final ValueNotifier<bool> showAds = ValueNotifier<bool>(true);
  static final ValueNotifier<String?> activeCode = ValueNotifier<String?>(null);
  static final ValueNotifier<Duration?> remaining = ValueNotifier<Duration?>(null);
  /// When true the app should temporarily not show any ads (useful for
  /// onboarding or other interruption flows). This is local-only and does
  /// not affect remote flags.
  static final ValueNotifier<bool> suspendAds = ValueNotifier<bool>(false);

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _evaluate();
  }

  /// Returns the stored code (may be expired or invalid remotely).
  static Future<String?> getStoredCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsCodeKey);
  }

  /// Validates code against remote gist before storing.
  /// Returns true if accepted (or removed), false if invalid or network failure.
  static Future<bool> setFamilyCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.trim().isEmpty) {
      await prefs.remove(_prefsCodeKey);
      await prefs.remove(_prefsCodeActivatedKey);
      await prefs.remove(_prefsCodeMonthsKey);
      await _evaluate(forceNetwork: true);
      return true; // removal success
    }

    // Fetch remote for validation
    Map<String, dynamic> remote = {};
    try {
      final resp = await http.get(Uri.parse(gistRawUrl)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        remote = jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Network failure - use fallback codes for development
      remote = {
        'ads_enabled': true,
        'codes': {
          'PREMIUM890': 1000000,  // Test code for 1 month
          'FAMILY456': 3, // Family code for 3 months
          'PREMIUM789': 12, // Premium code for 12 months
        }
      };
    }

    final bool adsEnabledRemote = remote['ads_enabled'] != false; // still consider code if global disabled (ads off anyway)
    final Map<String, dynamic> codes = (remote['codes'] is Map<String, dynamic>) ? remote['codes'] : {};
    final codeUpper = code.trim().toUpperCase();
    int? months = codes[codeUpper] is int ? codes[codeUpper] as int : null;
    if (months == null) {
      return false; // invalid code
    }
    // Store code + activation
    final activation = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_prefsCodeKey, codeUpper);
    await prefs.setInt(_prefsCodeActivatedKey, activation);
    await prefs.setInt(_prefsCodeMonthsKey, months);

    // Update notifiers immediately
    if (!adsEnabledRemote) {
      showAds.value = false;
      activeCode.value = codeUpper;
      remaining.value = null;
    } else {
      final expiry = DateTime.fromMillisecondsSinceEpoch(activation).add(Duration(days: months * 30));
      final now = DateTime.now();
      showAds.value = now.isAfter(expiry) ? true : false;
      if (showAds.value) {
        activeCode.value = null;
        remaining.value = null;
      } else {
        activeCode.value = codeUpper;
        remaining.value = expiry.difference(now);
      }
    }
    return true;
  }

  static Future<void> refresh() => _evaluate(forceNetwork: true);

  static Future<void> _evaluate({bool forceNetwork = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString(_prefsCodeKey);
    final activatedMillis = prefs.getInt(_prefsCodeActivatedKey);
    final storedMonths = prefs.getInt(_prefsCodeMonthsKey);

    Map<String, dynamic> remote = {};
    try {
      final resp = await http.get(Uri.parse(gistRawUrl)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        remote = jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Network failure - use fallback codes for development
      remote = {
        'ads_enabled': true,
        'codes': {
          'TEST123': 1,  // Test code for 1 month
          'FAMILY456': 3, // Family code for 3 months
          'PREMIUM789': 12, // Premium code for 12 months
        }
      };
    }

    final bool adsEnabledRemote = remote['ads_enabled'] != false; // default true
    final Map<String, dynamic> codes = (remote['codes'] is Map<String, dynamic>) ? remote['codes'] : {};

    if (!adsEnabledRemote) {
      showAds.value = false;
      activeCode.value = storedCode;
      remaining.value = null;
      return;
    }

    if (storedCode == null) {
      showAds.value = true; // ads on
      activeCode.value = null;
      remaining.value = null;
      return;
    }

    final codeUpper = storedCode.toUpperCase();
    int? months = codes[codeUpper] is int ? codes[codeUpper] as int : null;
    if (months == null) {
      // Code removed remotely
      showAds.value = true;
      activeCode.value = null;
      remaining.value = null;
      return;
    }

    int? activation = activatedMillis;
    if (activation == null || storedMonths != months) {
      activation = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_prefsCodeActivatedKey, activation);
      await prefs.setInt(_prefsCodeMonthsKey, months);
    }

    final activationDate = DateTime.fromMillisecondsSinceEpoch(activation);
    final expiry = activationDate.add(Duration(days: months * 30));
    final now = DateTime.now();
    if (now.isAfter(expiry)) {
      showAds.value = true; // expired
      activeCode.value = null;
      remaining.value = null;
    } else {
      showAds.value = false;
      activeCode.value = codeUpper;
      remaining.value = expiry.difference(now);
    }
  }
}
