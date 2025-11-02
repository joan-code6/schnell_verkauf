import 'package:flutter/material.dart';
import '../services/api_key_manager.dart';
import '../services/ads_service.dart';
import 'camera_screen.dart';
import 'api_key_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasApiKey = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await ApiKeyManager.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
      _isLoading = false;
    });
  }

  void _navigateToCamera() {
    if (!_hasApiKey) {
      _showApiKeyRequiredDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  void _showApiKeyRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API-Schlüssel erforderlich'),
        content: const Text(
          'Um die KI-Funktionen zu nutzen, müssen Sie zuerst einen Gemini API-Schlüssel konfigurieren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Einstellungen'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiKeySettingsScreen(),
      ),
    );
    _checkApiKey(); // Refresh API key status
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () async {
            final controller = TextEditingController();
            await showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Familien Code eingeben'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Code oder leer zum Löschen'),
                  autofocus: true,
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Abbrechen')),
                  TextButton(
                    onPressed: () async {
                      final code = controller.text.trim();
                      Navigator.pop(c);
                      final ok = await AdsService.setFamilyCode(code.isEmpty ? null : code);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            code.isEmpty
                                ? (ok ? 'Code entfernt' : 'Entfernen fehlgeschlagen')
                                : (ok ? 'Code aktiviert' : 'Code ungültig'),
                          ),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Schnell Verkaufen'),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 100),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // API Key status warning
                    if (!_hasApiKey)
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[200]!, width: 1),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'API-Schlüssel erforderlich',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Konfigurieren Sie einen Gemini API-Schlüssel in den Einstellungen für KI-Funktionen.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _navigateToSettings,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Jetzt konfigurieren'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            
                    // Hero section
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            // App icon
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _hasApiKey 
                                    ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                    : [Colors.grey[400]!, Colors.grey[500]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_hasApiKey ? const Color(0xFF4CAF50) : Colors.grey[400]!).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Title
                            const Text(
                              'Schnell Verkaufen',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Subtitle
                            Text(
                              'Verkaufe deine Produkte schnell und einfach',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Ad-free status
                    ValueListenableBuilder(
                      valueListenable: AdsService.showAds,
                      builder: (context, showAdsValue, _) {
                        if (showAdsValue) {
                          return const SizedBox.shrink();
                        }
                        return ValueListenableBuilder(
                          valueListenable: AdsService.remaining,
                          builder: (context, remaining, __) {
                            if (remaining == null) return const SizedBox.shrink();
                            final days = remaining.inDays;
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.stars_rounded,
                                        color: Color(0xFF4CAF50),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Werbefrei noch ca. ${days > 0 ? '$days Tage' : 'wenige Stunden'}',
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    
                    // Main action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToCamera,
                        icon: const Icon(Icons.camera_alt_rounded, size: 24),
                        label: const Text('Foto aufnehmen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // How it works section
                    Card(
                      elevation: 0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'So funktioniert es',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildHowToStep(
                              icon: Icons.camera_alt_rounded,
                              step: '1',
                              title: 'Foto aufnehmen',
                              description: 'Mache ein oder mehrere Fotos von deinem Produkt',
                            ),
                            const SizedBox(height: 16),
                            _buildHowToStep(
                              icon: Icons.smart_toy_rounded,
                              step: '2', 
                              title: 'KI-Analyse',
                              description: 'Unsere KI erstellt automatisch eine Produktbeschreibung',
                            ),
                            const SizedBox(height: 16),
                            _buildHowToStep(
                              icon: Icons.sell_rounded,
                              step: '3',
                              title: 'Verkaufen',
                              description: 'Teile die Beschreibung auf deiner bevorzugten Plattform',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHowToStep({
    required IconData icon,
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
