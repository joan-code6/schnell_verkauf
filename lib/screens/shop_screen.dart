import 'package:flutter/material.dart';
import '../services/ads_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  void _showContactDialog(BuildContext context, String produkt, String preis) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kauf abschließen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Produkt: $produkt'),
              Text('Preis: $preis'),
              const SizedBox(height: 12),
              const Text('Da ich ein kleiner Entwickler bin, läuft die Abwicklung per E‑Mail.'),
              const SizedBox(height: 8),
              const SelectableText('Bitte schreibe an: purchase@joancode.33mail.com'),
              const SizedBox(height: 8),
              const Text('Betreff: Schnell Verkaufen Kauf + Produktname'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.email),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final subject = Uri.encodeComponent('Schnell Verkaufen Kauf: $produkt');
                    final body = Uri.encodeComponent('Hallo,\n\nich möchte folgendes kaufen:\nProdukt: $produkt\nPreis: $preis\n\n(Optional Feedback / Fragen hier)');
                    final uri = Uri.parse('mailto:purchase@joancode.33mail.com?subject=$subject&body=$body');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Konnte E-Mail App nicht öffnen')),
                        );
                      }
                    }
                  },
                  label: const Text('E-Mail schreiben'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Schließen')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop & Vorteile'),
        backgroundColor: Colors.orange,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: AdsService.showAds,
        builder: (context, showAds, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unterstütze die Entwicklung und hol dir Vorteile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.block, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Einmalig Werbung entfernen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Zahle einmalig und nutze die App werbefrei (ohne KI Flatrate).'),
                        const SizedBox(height: 8),
                        const Text('Preis: einmalig 4€', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _showContactDialog(context, 'Werbung entfernen (einmalig)', '4€'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          child: const Text('Jetzt Unterstützen'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('Unendlich Anfragen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Unbegrenzte KI-Anfragen (fair use) und keine Werbung solange aktiv.'),
                        const SizedBox(height: 8),
                        const Text('Preis: 10€ / Monat', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _showContactDialog(context, 'Monatsabo Unlimited', '10€/Monat'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          child: const Text('Jetzt Unterstützen'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Warum unterstützen?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Ich bin ein einzelner Entwickler. Mit deiner Unterstützung kann ich Server‑, API‑ und Entwicklungskosten decken und neue Features bauen.'),
                const SizedBox(height: 24),
                if (!showAds) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Danke für deine Unterstützung! ❤️', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
