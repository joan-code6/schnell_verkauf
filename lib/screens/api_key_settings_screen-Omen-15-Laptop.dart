import 'package:flutter/material.dart';
import '../services/api_key_manager.dart';
import '../services/kleinanzeigen_service.dart';
import '../services/ads_service.dart';
import '../services/smart_pricing_settings.dart';
import '../services/ads_agent_key_manager.dart';
import 'package:flutter/services.dart';
import 'package:advertising_id/advertising_id.dart';
import 'privacy_policy_screen.dart';

class ApiKeySettingsScreen extends StatefulWidget {
  const ApiKeySettingsScreen({super.key});

  @override
  State<ApiKeySettingsScreen> createState() => _ApiKeySettingsScreenState();
}

class _ApiKeySettingsScreenState extends State<ApiKeySettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _hasApiKey = false;
  bool _obscureText = true;
  String? _familyCode; // stored code
  bool _loadingFamily = true;
  bool _hasKleinanzeigenCookies = false;
  bool _smartPricing = false;
  final TextEditingController _agentKeyController = TextEditingController();
  bool _hasAgentKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadFamilyCode();
    _loadKleinanzeigenCookieState();
  _loadSmartPricing();
  _loadAgentKey();
  }

  Future<void> _loadKleinanzeigenCookieState() async {
    final has = await KleinanzeigenService.hasCookies();
    if (!mounted) return;
    setState(() {
      _hasKleinanzeigenCookies = has;
    });
  }

  Future<void> _kleinanzeigenLogout() async {
    setState(() { _isLoading = true; });
    final ok = await KleinanzeigenService.clearCookiesAndLogout();
    if (!mounted) return;
    setState(() { _isLoading = false; _hasKleinanzeigenCookies = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Kleinanzeigen: Cookies gelöscht' : 'Kleinanzeigen: Keine oder Fehler beim Löschen'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _loadSmartPricing() async {
    final enabled = await SmartPricingSettings.isEnabled();
    if (!mounted) return;
    setState(() { _smartPricing = enabled; });
  }

  Future<void> _toggleSmartPricing(bool v) async {
    await SmartPricingSettings.setEnabled(v);
    if (!mounted) return;
    setState(() { _smartPricing = v; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Smart Pricing ${v ? 'aktiviert' : 'deaktiviert'}')),
    );
  }

  Future<void> _loadAgentKey() async {
    final key = await AdsAgentKeyManager.getKey();
    if (!mounted) return;
    setState(() {
      _hasAgentKey = key != null && key.isNotEmpty;
      if (key != null) _agentKeyController.text = key;
    });
  }

  Future<void> _saveAgentKey() async {
    final v = _agentKeyController.text.trim();
    if (v.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent API Key darf nicht leer sein'), backgroundColor: Colors.red));
      return;
    }
    await AdsAgentKeyManager.saveKey(v);
    await _loadAgentKey();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent API Key gespeichert'), backgroundColor: Colors.green));
  }

  Future<void> _clearAgentKey() async {
    await AdsAgentKeyManager.clearKey();
    await _loadAgentKey();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent API Key gelöscht'), backgroundColor: Colors.orange));
  }

  Future<void> _showDebugInfo() async {
    String? adId;
    bool limitAdTracking = false;
    try {
      adId = await AdvertisingId.id(true);
    } catch (e) {
      adId = null;
    }
    try {
      final lat = await AdvertisingId.isLimitAdTrackingEnabled;
      limitAdTracking = lat ?? false;
    } catch (_) {}

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Debug Informationen'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Werbe-ID: ${adId ?? 'nicht verfügbar'}'),
              const SizedBox(height: 8),
              Text('Limit Ad Tracking: ${limitAdTracking ? 'Ja' : 'Nein'}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Schließen')),
          TextButton(
            onPressed: adId == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: adId ?? ''));
                    Navigator.pop(c);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Werbe-ID kopiert')));
                  },
            child: const Text('Werbe-ID kopieren'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFamilyCode() async {
    final code = await AdsService.getStoredCode();
    if (mounted) {
      setState(() {
        _familyCode = code;
        _loadingFamily = false;
      });
    }
  }

  Future<void> _setFamilyCode() async {
    final controller = TextEditingController(text: _familyCode ?? '');
    final newCode = await showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Premium Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Code eingeben oder leer lassen zum Entfernen',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('Speichern')),
        ],
      ),
    );
    if (newCode == null) return; // cancelled
    final ok = await AdsService.setFamilyCode(newCode.isEmpty ? null : newCode);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code ungültig oder Netzwerkfehler'), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newCode.isEmpty ? 'Code entfernt' : 'Code aktiviert'), backgroundColor: Colors.green));
    }
    _loadFamilyCode();
  }

  Future<void> _loadApiKey() async {
    final hasKey = await ApiKeyManager.hasApiKey();
    if (hasKey) {
      final apiKey = await ApiKeyManager.getApiKey();
      _apiKeyController.text = apiKey!;
    }
    setState(() {
      _hasApiKey = hasKey;
    });
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte geben Sie einen gültigen API-Schlüssel ein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiKeyManager.saveApiKey(_apiKeyController.text.trim());
      setState(() {
        _hasApiKey = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API-Schlüssel erfolgreich gespeichert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API-Schlüssel löschen'),
        content: const Text('Möchten Sie den gespeicherten API-Schlüssel wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiKeyManager.clearApiKey();
      _apiKeyController.clear();
      setState(() {
        _hasApiKey = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API-Schlüssel gelöscht'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showApiKeyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API-Schlüssel'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'So erhalten Sie einen Gemini API-Schlüssel:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Besuchen Sie https://makersuite.google.com/app/apikey'),
              SizedBox(height: 4),
              Text('2. Melden Sie sich mit Ihrem Google-Konto an'),
              SizedBox(height: 4),
              Text('3. Klicken Sie auf "Create API Key"'),
              SizedBox(height: 4),
              Text('4. Kopieren Sie den generierten Schlüssel'),
              SizedBox(height: 4),
              Text('5. Fügen Sie ihn hier ein'),
              SizedBox(height: 16),
              Text(
                'Hinweis: Der API-Schlüssel wird sicher auf Ihrem Gerät gespeichert.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
  _agentKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showApiKeyInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Gemini API-Schlüssel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'API-Schlüssel eingeben',
                        hintText: 'AIza...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveApiKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Speichern'),
                          ),
                        ),
                        if (_hasApiKey) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _clearApiKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Löschen'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Wichtige Informationen',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Ihr API-Schlüssel wird nur lokal auf diesem Gerät gespeichert\n'
                      '• Die App verwendet Gemini 2.0 Flash für die Bildanalyse\n'
                      '• Stellen Sie sicher, dass Ihr API-Schlüssel gültig ist\n'
                      '• Bei Problemen überprüfen Sie Ihre Internetverbindung',
                    ),
                  ],
                ),
              ),
            ),
            if (_hasApiKey)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'API-Schlüssel ist konfiguriert',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Smart Pricing toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.trending_up, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Smart Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Wenn aktiviert, analysiert die KI zusätzlich aktuelle Angebote und optimiert den Preis automatisch.'),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Smart Pricing aktivieren'),
                      value: _smartPricing,
                      onChanged: (v) => _toggleSmartPricing(v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Kleinanzeigen Agent API Key
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [Icon(Icons.search, color: Colors.orange), SizedBox(width: 8), Text('Agent API-key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 12),
                    const Text('Für Marktpreis-Abgleich (Smart Pricing). \nErhalten sie den Key von kleinanzeigen-agent.de'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _agentKeyController,
                      decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveAgentKey,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          child: const Text('Speichern'),
                        ),
                      ),
                      if (_hasAgentKey) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _clearAgentKey,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Löschen'),
                        ),
                      ]
                    ])
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Family code section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lock, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Secret Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Really secret!!!',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: AdsService.showAds,
                      builder: (context, adsOn, _) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: AdsService.activeCode,
                          builder: (context, activeCode, __) {
                            return ValueListenableBuilder<Duration?>(
                              valueListenable: AdsService.remaining,
                              builder: (context, remaining, ___) {
                                final active = !adsOn && activeCode != null;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_loadingFamily)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 8.0),
                                        child: LinearProgressIndicator(minHeight: 4),
                                      )
                                    else if (active)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green.withOpacity(.3)),
                                        ),
                                        child: Text(
                                          'Aktiv: $activeCode – verbleibend ~${remaining != null ? remaining.inDays : '?'} Tage',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                        ),
                                      )
                                    else if (_familyCode != null)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.withOpacity(.3)),
                                        ),
                                        child: Text(
                                          'Code gespeichert aber abgelaufen / ungültig: $_familyCode',
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _setFamilyCode,
                                        icon: const Icon(Icons.edit),
                                        label: Text(_familyCode == null ? 'Code eingeben' : 'Code ändern / entfernen'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Kleinanzeigen Login',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Melden Sie sich hier bei Kleinanzeigen.de an. Ihre Session bleibt mittels Cookie gespeichert. Bei Ablauf können Sie sich erneut einloggen.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _hasKleinanzeigenCookies
                          ? OutlinedButton.icon(
                              onPressed: _isLoading ? null : _kleinanzeigenLogout,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Kleinanzeigen Logout',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                            )
                          : OutlinedButton.icon(
                              onPressed: () async {
                                await KleinanzeigenService.showLoginWebView(context);
                                // Refresh cookie state when returning from the login webview
                                await _loadKleinanzeigenCookieState();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.login, color: Colors.orange),
                              label: const Text(
                                'Bei Kleinanzeigen anmelden',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [Icon(Icons.bug_report, color: Colors.orange), SizedBox(width: 8), Text('Debug Informationen', style: TextStyle(fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(
                            onPressed: _showDebugInfo,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Debug Informationen anzeigen'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (c) => const PrivacyPolicyScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Datenschutz / Privacy Policy anzeigen'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ),
        ),
      ),
    );
  }
}
