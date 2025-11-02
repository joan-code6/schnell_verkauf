import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_data.dart';
import '../screens/home_screen.dart';

class KleinanzeigenService {
  static const String loginUrl = 'https://www.kleinanzeigen.de/m-einloggen.html';
  static const String postAdUrl = 'https://www.kleinanzeigen.de/p-anzeige-aufgeben-schritt2.html';
  static const String _prefsKey = 'kleinanzeigen_has_cookies';
  
  static Future<void> showLoginWebView(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KleinanzeigenLoginScreen(),
      ),
    );
  }
  
  static Future<void> showPostAdWebView(BuildContext context, ProductData productData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KleinanzeigenPostAdScreen(productData: productData),
      ),
    );
  }

  // Persist a small flag to remember if the user previously logged in via the WebView
  // (we set this after detecting a successful navigation away from the login page).
  static Future<void> _setHasCookies(bool v) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_prefsKey, v);
    } catch (e) {
    }
  }

  // Public helper to mark that the user has an active kleinanzeigen session (cookies stored)
  static Future<void> markHasCookies() async => _setHasCookies(true);

  static Future<bool> hasCookies() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getBool(_prefsKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Clears webview cookies and resets our persisted flag.
  static Future<bool> clearCookiesAndLogout() async {
    try {
      final cleared = await WebViewCookieManager().clearCookies();
      await _setHasCookies(false);
      return cleared;
    } catch (e) {
      await _setHasCookies(false);
      return false;
    }
  }
}

class KleinanzeigenLoginScreen extends StatefulWidget {
  const KleinanzeigenLoginScreen({super.key});

  @override
  State<KleinanzeigenLoginScreen> createState() => _KleinanzeigenLoginScreenState();
}

class _KleinanzeigenLoginScreenState extends State<KleinanzeigenLoginScreen> {
  late final WebViewController _controller;
  bool _cookiesDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            try {
              // Prefer a direct cookie check inside the WebView — more reliable than URL heuristics.
              final raw = await _controller.runJavaScriptReturningResult('document.cookie');
              final cookieString = raw.toString();
              // Some platforms return quoted strings like '"a=b"', so trim quotes
              final cleaned = cookieString.replaceAll('"', '').trim();
              if (cleaned.isNotEmpty) {
                // Record detection but do NOT pop immediately. Some sites set cookies
                // early during the login flow which would kick the user out.
                _cookiesDetected = true;
              }
            } catch (e) {
              // ignore JS failures and fall back to URL heuristic
            }

            // Only close the login screen when the URL leaves the login page AND cookies were detected.
            if (!url.contains('einloggen') && _cookiesDetected && mounted) {
              KleinanzeigenService.markHasCookies();
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) Navigator.pop(context);
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
          },
        ),
      )
      ..loadRequest(Uri.parse(KleinanzeigenService.loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kleinanzeigen Login'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class KleinanzeigenPostAdScreen extends StatefulWidget {
  final ProductData productData;
  
  const KleinanzeigenPostAdScreen({
    super.key,
    required this.productData,
  });

  @override
  State<KleinanzeigenPostAdScreen> createState() => _KleinanzeigenPostAdScreenState();
}

class _KleinanzeigenPostAdScreenState extends State<KleinanzeigenPostAdScreen> {
  late final WebViewController _controller;
  bool _imagesInjected = false;
  bool _sessionChecked = false;
  bool _successShown = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            // Basic session check: if redirected back to login, inform user
            if (url.contains('einloggen')) {
              if (mounted && _sessionChecked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Session abgelaufen – bitte erneut einloggen.'),
                    action: SnackBarAction(
                      label: 'Einstellungen',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/settings');
                      },
                    ),
                  ),
                );
              }
            }
            if (url.contains('anzeige-aufgeben-schritt2')) {
              _sessionChecked = true;
              _fillFormData();
            }
            // Success detection: rely solely on reaching the confirmation URL.
            if (!_successShown && url.contains('p-anzeige-aufgeben-bestaetigung.html')) {
              _successShown = true;
              if (mounted) {
                // small delay to let page settle (optional)
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) _showSuccessAndNavigateHome();
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(KleinanzeigenService.postAdUrl));
  }

  Future<void> _fillFormData() async {
    // Wait a bit for the page to fully load
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Fill title
    await _controller.runJavaScript('''
      var titleField = document.getElementById('postad-title');
      if (titleField) {
        titleField.value = '${widget.productData.title}';
        titleField.dispatchEvent(new Event('input', { bubbles: true }));
      }
    ''');
    
    // Fill price
    await _controller.runJavaScript('''
      var priceField = document.getElementById('micro-frontend-price');
      if (priceField) {
        priceField.value = '${widget.productData.price.toStringAsFixed(0)}';
        priceField.dispatchEvent(new Event('input', { bubbles: true }));
      }
    ''');
    
    // Fill description
    await _controller.runJavaScript('''
      var descField = document.getElementById('pstad-descrptn');
      if (descField) {
        descField.value = '${widget.productData.description.replaceAll('\n', '\\n').replaceAll('\'', '\\\'').replaceAll('"', '\\"')}';
        descField.dispatchEvent(new Event('input', { bubbles: true }));
      }
    ''');

    // Attempt to upload images automatically
    if (!_imagesInjected) {
      _imagesInjected = true;
      _uploadImages();
    }
  }

  Future<void> _uploadImages() async {
    // Some sites dynamically create the file input only after a user click.
    // We'll try to ensure it's present by triggering the add button first.
    await Future.delayed(const Duration(milliseconds: 500));
    await _controller.runJavaScript('''
      var addBtn = document.getElementById('pictureupload-pickfiles-icon');
      if(addBtn){ addBtn.click(); }
    ''');

    // Inject each image sequentially with a slight delay
    for (int i = 0; i < widget.productData.imagePaths.length; i++) {
      final path = widget.productData.imagePaths[i];
      try {
        final bytes = await File(path).readAsBytes();
        final b64 = base64Encode(bytes);
        final safeName = 'schnellverkauf_${i + 1}.jpg';

        // To avoid extremely long single JS strings, we split the base64 into chunks and reassemble
        final chunkSize = 8000; // conservative
        final chunks = <String>[];
        for (var p = 0; p < b64.length; p += chunkSize) {
          chunks.add(b64.substring(p, p + chunkSize > b64.length ? b64.length : p + chunkSize));
        }
        final jsArrayLiteral = chunks.map((c) => "'${c.replaceAll("'", "\\'")}'").join(',');

        final js = '''(function(){
          try {
            // Rebuild base64
            var parts = [$jsArrayLiteral];
            var b64 = parts.join('');
            var byteChars = atob(b64);
            var byteNumbers = new Array(byteChars.length);
            for (var i=0;i<byteChars.length;i++){ byteNumbers[i]=byteChars.charCodeAt(i);} 
            var byteArray = new Uint8Array(byteNumbers);
            var blob = new Blob([byteArray], {type:'image/jpeg'});
            var file = new File([blob], '$safeName', {type:'image/jpeg'});
            var input = document.querySelector('#dropzone-box input[type=file]') || document.querySelector('input[type=file]');
            if(!input){
              var addBtn = document.getElementById('pictureupload-pickfiles-icon');
              if(addBtn){ addBtn.click(); }
              input = document.querySelector('#dropzone-box input[type=file]') || document.querySelector('input[type=file]');
            }
            if(!input){ console.log('No file input found for injection'); return; }
            var dt = new DataTransfer();
            // Preserve existing files if any
            if(input.files && input.files.length){
              for (var k=0; k<input.files.length; k++){ dt.items.add(input.files[k]); }
            }
            dt.items.add(file);
            input.files = dt.files;
            input.dispatchEvent(new Event('change', {bubbles:true}));
            console.log('Injected file $safeName');
          } catch(e){ console.log('Injection error', e); }
        })();''';

        await _controller.runJavaScript(js);
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e) {
      }
    }

    // Optional: Inform user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bilder wurden eingefügt – sie können nun die Reihenfolge ändern.')),
      );
    }
  }

  void _showSuccessAndNavigateHome() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          title: const Text(
            'Erfolgreich hochgeladen!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Dein Produkt wurde erfolgreich zu Kleinanzeigen hinzugefügt.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Zur Startseite'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anzeige aufgeben'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hinweis'),
                  content: const Text(
                    'Die Formularfelder wurden automatisch ausgefüllt. '
                    'Bitte fügen Sie die Bilder manuell hinzu, da diese aus der Galerie ausgewählt werden müssen.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
  // ...existing code...
    );
  }
}
