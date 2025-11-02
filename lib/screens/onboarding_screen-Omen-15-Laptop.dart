import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/onboarding_service.dart';
import '../services/api_key_manager.dart';
import '../services/kleinanzeigen_service.dart';
import '../services/ads_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _anim; // Intro animations
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final TextEditingController _apiKeyController;
  int _index = 0;
  bool _checkingKey = true;
  bool _hasKey = false;
  bool _loggedIn = false; // Kleinanzeigen Login Status
  // Show API key by default (not a password field) so users can paste easily
  bool _obscureApiKey = false;
  bool _savingApiKey = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _apiKeyController = TextEditingController();
  _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  _fade = CurvedAnimation(parent: _anim, curve: const Interval(.15, 1, curve: Curves.easeOutCubic));
  _scale = CurvedAnimation(parent: _anim, curve: const Interval(0, .55, curve: Curves.easeOutBack));
  // Start a slight delayed animation for nicer feel
  Future.delayed(const Duration(milliseconds: 120), () { if (mounted) _anim.forward(); });
    _loadKey();
    // Temporarily suspend global banners while onboarding is active
    AdsService.suspendAds.value = true;
  }

  @override
  void dispose() {
    // Restore ad visibility when leaving onboarding
    AdsService.suspendAds.value = false;
    _pageController.dispose();
    _anim.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final key = await ApiKeyManager.getApiKey();
    if (key != null && key.isNotEmpty) {
      _apiKeyController.text = key;
    }
    _hasKey = await ApiKeyManager.hasApiKey();
    setState(() { _checkingKey = false; });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen API Key eingeben')),
      );
      return;
    }

    setState(() { _savingApiKey = true; });
    
    try {
      await ApiKeyManager.saveApiKey(key);
      setState(() {
        _hasKey = true;
        _savingApiKey = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key erfolgreich gespeichert')),
      );
    } catch (e) {
      setState(() { _savingApiKey = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    }
  }

  void _next() async {
    if (_index == 0) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      return;
    }
    // API Key page (index 1): enforce key set
    if (_index == 1 && !_hasKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst einen API Key eingeben')),
      );
      return;
    }
    if (_index == 1 && _hasKey) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      return;
    }
    // Login page (index 2): enforce login before finishing
    if (_index == 2 && !_loggedIn) {
      _openLoginFlow();
      return;
    }
    // Finish after all gating conditions satisfied
    if (_index == 2 && _loggedIn && _hasKey) {
      await OnboardingService.setCompleted();
      // Onboarding finished: re-enable banners according to AdsService logic
      AdsService.suspendAds.value = false;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _openLoginFlow() async {
    await KleinanzeigenService.showLoginWebView(context);
    if (!mounted) return;
    setState(() { _loggedIn = true; });
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        children: [
          if (_index > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              child: const Text('Zurück'),
            )
          else
            const SizedBox(width: 80),
          const Spacer(),
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              _index == 0
                  ? 'Weiter'
                  : _index == 1 && !_hasKey
                      ? 'API Key setzen'
                      : _index == 1 && _hasKey
                          ? 'Weiter'
                          : _index == 2 && !_loggedIn
                              ? 'Bei Kleinanzeigen einloggen'
                              : 'Starten',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingKey) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

  return Scaffold(
      body: Container(
        decoration: _index == 0
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : const BoxDecoration(color: Colors.white), // ensure clean page, no bleed-through
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Enforce gating
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _IntroPage(fade: _fade, scale: _scale),
                    _ApiKeyPage(
              hasKey: _hasKey,
              apiKeyController: _apiKeyController,
              obscureApiKey: _obscureApiKey,
              savingApiKey: _savingApiKey,
              onToggleObscure: () => setState(() { _obscureApiKey = !_obscureApiKey; }),
              onSaveApiKey: _saveApiKey,
            ),
                    _LoginInfoPage(loggedIn: _loggedIn, onLogin: _openLoginFlow),
                  ],
                ),
              ),
              _Dots(index: _index, total: 3),
              _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final Animation<double> fade; final Animation<double> scale;
  const _IntroPage({required this.fade, required this.scale});
  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: Colors.white,
      shadows: const [Shadow(blurRadius: 14, color: Color(0x55000000), offset: Offset(0, 4))],
      height: 1.04,
      letterSpacing: .2,
    );

    return Stack(
      children: [
        // Animated soft circles background
        const _AnimatedBackground(),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
            child: FadeTransition(
              opacity: fade,
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const SweepGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFFC107), Color(0xFFFF9800)],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: -4, offset: Offset(0, 12)),
                              ],
                            ),
                            child: const Icon(Icons.flash_on, size: 88, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 42),
                        // Readability panel
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
                          constraints: const BoxConstraints(maxWidth: 560),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.32),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(.12)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 14)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text('Schnell Verkaufen', textAlign: TextAlign.center, style: headlineStyle),
                              const SizedBox(height: 18),
                              const Text(
                                'Fotos aufnehmen – KI erkennt Details, erstellt Titel, Beschreibung & Preisvorschlag. Du bestätigst und veröffentlichst. Schneller, sauberer, smarter.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 16.5, height: 1.34, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 22),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _FeatureChip(icon: Icons.bolt, text: 'Sehr schnell'),
                                  _FeatureChip(icon: Icons.camera_alt, text: 'Bildanalyse'),
                                  _FeatureChip(icon: Icons.auto_fix_high, text: 'KI Text'),
                                  _FeatureChip(icon: Icons.price_check, text: 'Preisvorschlag'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Made to simplify selling', style: TextStyle(color: Colors.white54, fontSize: 12.5, letterSpacing: 1.05)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon; final String text; const _FeatureChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(.25),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF9500), Color(0xFFFFC107)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _BlobPainter(t),
          ),
        );
      },
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t; _BlobPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
  paint.color = const Color(0xFFFFFFFF).withOpacity(.05); // reduce brightness for readability

    Path softBlob(double shift, double scale) {
      final w = size.width; final h = size.height;
      final cx = w * (.5 + .15 * (scale) * (0.5 - (t + shift) % 1));
      final cy = h * (.45 + .25 * (scale) * (((t * 1.3 + shift) % 1) - .5));
      final r = (w * .65 * scale) * (1 + .05 * (t * 4 % 1));
      return Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    }

    for (final spec in [
      [0.0, 1.0],
      [0.33, .7],
      [0.66, .5],
    ]) {
      canvas.drawPath(softBlob(spec[0], spec[1]), paint);
    }

    // Light gradient overlay vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(.35)],
        stops: const [0.6, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette..blendMode = BlendMode.darken);
  }
  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => true;
}

class _ApiKeyPage extends StatelessWidget {
  final bool hasKey;
  final TextEditingController apiKeyController;
  final bool obscureApiKey;
  final bool savingApiKey;
  final VoidCallback onToggleObscure;
  final VoidCallback onSaveApiKey;
  
  const _ApiKeyPage({
    required this.hasKey,
    required this.apiKeyController,
    required this.obscureApiKey,
    required this.savingApiKey,
    required this.onToggleObscure,
    required this.onSaveApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.key, size: 100, color: Colors.orange),
          const SizedBox(height: 24),
          Text('Dein kostenloser KI Zugang',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Für die automatische Analyse und Texterstellung nutzt die App Googles Gemini KI. Du brauchst dafür einen persönlichen (kostenlosen) API Key.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _InfoTile(icon: Icons.lock_open, text: 'Kostenlos & schnell erstellt'),
          _InfoTile(icon: Icons.security, text: 'Nur lokal gespeichert – kein Serverzugriff'),
          _InfoTile(icon: Icons.speed, text: 'Ermöglicht Bildanalyse & Preisvorschlag'),
          const SizedBox(height: 24),
          _StepsBox(steps: const [
              'Erstelle oder wähle zuerst ein Google Cloud Projekt (console.cloud.google.com)',
              'Gehe zu https://makersuite.google.com/app/apikey',
              'Mit Google Konto anmelden',
              'Neuen API Key erzeugen (ggf. erforderliche APIs aktivieren)',
              'Key kopieren & hier einfügen',
          ]),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Tipp: Tippe die URL an, um sie im Browser zu öffnen. Möglicherweise musst du im Cloud-Projekt die APIs aktivieren oder Abrechnungsinfo hinzufügen (bei manchen Google-Diensten).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            // Probleme / Support button (more visible)
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () => _showSupportDialog(context),
                icon: const Icon(Icons.help_outline, color: Colors.white),
                label: const Text('Probleme?'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // API Key Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Key eingeben:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apiKeyController,
                  obscureText: obscureApiKey,
                  keyboardType: TextInputType.text,
                  enableSuggestions: true,
                  autocorrect: false,
                  enableInteractiveSelection: true,
                  decoration: InputDecoration(
                    hintText: 'Füge hier deinen Gemini API Key ein',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureApiKey ? Icons.visibility : Icons.visibility_off),
                      onPressed: onToggleObscure,
                    ),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: savingApiKey ? null : onSaveApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: savingApiKey
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('API Key speichern'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (hasKey)
            const Text('API Key gespeichert ✅', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

class _LoginInfoPage extends StatelessWidget {
  final bool loggedIn;
  final VoidCallback onLogin;
  const _LoginInfoPage({required this.loggedIn, required this.onLogin});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
            const Icon(Icons.account_circle, size: 100, color: Colors.orange),
            const SizedBox(height: 24),
            Text('Login bei Kleinanzeigen', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Melde dich jetzt einmalig bei Kleinanzeigen.de an. Deine Session bleibt per Cookie erhalten. Läuft sie ab, wirst du automatisch wieder zum Login geleitet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: Icon(loggedIn ? Icons.check_circle : Icons.login),
              label: Text(loggedIn ? 'Eingeloggt' : 'Jetzt einloggen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: loggedIn ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (loggedIn)
              const Text('Login gespeichert ✅', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 32),
            const Text(
              'Nach erfolgreichem Login kannst du direkt Anzeigen erstellen – Titel, Beschreibung, Preis und Bilder werden vorbereitet.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String text; const _InfoTile({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      dense: true,
      title: Text(text),
    );
  }
}

class _StepsBox extends StatelessWidget {
  final List<String> steps; const _StepsBox({required this.steps});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('So holst du dir den Key:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((e) {
            final text = e.value;
            // Known URLs we want clickable
            final makersuiteUrl = 'https://makersuite.google.com/app/apikey';
            final consoleUrl = 'https://console.cloud.google.com';
            if (text.contains(makersuiteUrl)) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: _ClickableUrlText(text: text, url: makersuiteUrl)),
                  ],
                ),
              );
            }
            if (text.contains('console.cloud.google.com') || text.contains(consoleUrl)) {
              // Accept both with and without scheme
              final detected = text.contains(consoleUrl) ? consoleUrl : 'https://console.cloud.google.com';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: _ClickableUrlText(text: text, url: detected)),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(text)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ClickableUrlText extends StatelessWidget {
  final String text;
  final String url;
  const _ClickableUrlText({required this.text, required this.url});

  Future<void> _launchUrl() async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Render original text but style the URL portion to look clickable
    // Simple approach: split by the url and show clickable TextButton for the url
    final parts = text.split(url);
    return Wrap(
      children: [
        if (parts.isNotEmpty) Text(parts[0]),
        TextButton(
          onPressed: _launchUrl,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text(url, style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
        ),
        if (parts.length > 1) Text(parts.sublist(1).join(url)),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int index; final int total; const _Dots({required this.index, required this.total});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: active ? Colors.orange : Colors.orange.withOpacity(.3),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }
}

// (Old _GradientContainer removed – replaced by animated background)

// Support helpers
Future<void> _launchSupportEmail(BuildContext context) async {
  final email = 'bennet-wegener@web.de';
  final subject = Uri.encodeComponent('Support: Probleme mit API Key / Onboarding');
  final body = Uri.encodeComponent('Hallo Bennet,%0D%0A%0D%0Aich habe Probleme beim Einrichten des API Keys...\n\nBitte kurz melden.\n%0D%0A');
  final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
  if (!await launchUrl(uri)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-Mail konnte nicht geöffnet werden')),
    );
  }
}

void _showSupportDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Support kontaktieren'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bevor du eine E‑Mail schreibst, schau bitte zuerst diese Anleitung:') ,
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openGuide(ctx),
            icon: const Icon(Icons.open_in_new, color: Colors.orange),
            label: const Text('Gradually: Gemini API Guide', style: TextStyle(decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 8),
          const Text('Wenn das Problem dadurch nicht gelöst wird, kannst du uns per E‑Mail kontaktieren.'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            _launchSupportEmail(context);
          },
          child: const Text('E‑Mail schreiben'),
        ),
      ],
    ),
  );
}

Future<void> _openGuide(BuildContext context) async {
  final guide = Uri.parse('https://www.gradually.ai/google-gemini-api');
  if (!await launchUrl(guide, mode: LaunchMode.externalApplication)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guide konnte nicht geöffnet werden')));
  }
}
