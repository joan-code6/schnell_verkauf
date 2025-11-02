import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'edit_product_screen.dart';

class AdditionalInfoScreen extends StatefulWidget {
  // All images user captured (can be >3) for final posting
  final List<String> imagePaths;
  // Subset (<=3) chosen for AI analysis
  final List<String> aiImagePaths;
  
  const AdditionalInfoScreen({
    super.key,
    required this.imagePaths,
    required this.aiImagePaths,
  });

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  bool _isAnalyzing = false;
  final TextEditingController _additionalInfoController = TextEditingController();
  
  // Preset phrases for common product conditions
  final List<String> _presets = [
    'Funktionsfähig',
    'Neuwertig',
    'Ungeöffnet',
    'Sehr guter Zustand',
    'Guter Zustand',
    'Gebraucht',
    'Defekt',
    'Originalverpackung',
  ];
  
  void _addPresetText(String preset) {
    final currentText = _additionalInfoController.text;
    if (currentText.isEmpty) {
      _additionalInfoController.text = preset;
    } else {
      _additionalInfoController.text = '$currentText, $preset';
    }
  }
  
  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }
  
  Future<void> _analyzeWithAI() async {
  if (widget.aiImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Bitte mindestens ein Foto für die KI auswählen')),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final additionalInfo = _additionalInfoController.text.trim();
      // Only send selected AI images to Gemini, but keep full list when constructing ProductData
      final productData = await AIService.analyzeImages(
        widget.aiImagePaths,
        additionalInfo: additionalInfo,
      );
      // Overwrite imagePaths with ALL images for editing/posting
      final mergedProductData = productData.copyWith(imagePaths: widget.imagePaths);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditProductScreen(productData: mergedProductData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString();
        String errorMessage = 'Fehler bei der Analyse: $err';
        // Detect rate/quota messages from AIService and show friendlier text
        if (err.toLowerCase().contains('rate') || err.toLowerCase().contains('quota') || err.toLowerCase().contains('rate-limit')) {
          errorMessage = 'Rate-Limit erreicht oder Quota überschritten. Bitte warten Sie kurz und versuchen Sie es erneut.';
        } else if (err.toLowerCase().contains('analys') && err.toLowerCase().contains('arbeit')) {
          errorMessage = 'Analyse läuft bereits. Bitte warten.';
        }
        
        // Check if it's an API key error
        if (e.toString().contains('API-Schlüssel')) {
          errorMessage = 'API-Schlüssel nicht konfiguriert. Bitte gehen Sie zu den Einstellungen.';
          
          // Show settings dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('API-Schlüssel erforderlich'),
              content: const Text(
                'Um die KI-Analyse zu nutzen, müssen Sie einen Gemini API-Schlüssel in den Einstellungen konfigurieren.',
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zusätzliche Informationen'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zusätzliche Informationen für die KI:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Beschreiben Sie den Zustand oder besondere Eigenschaften des Produkts. Diese Informationen helfen der KI bei einer genaueren Analyse.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Text input field
                  TextField(
                    controller: _additionalInfoController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Beschreiben Sie den Zustand oder besondere Eigenschaften...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Preset buttons
                  const Text(
                    'Schnellauswahl:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((preset) {
                      return ActionChip(
                        label: Text(preset),
                        onPressed: () => _addPresetText(preset),
                        backgroundColor: Colors.orange[100],
                        labelStyle: const TextStyle(fontSize: 13),
                        side: BorderSide(color: Colors.orange[300]!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Photos summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_library, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.imagePaths.length} Foto${widget.imagePaths.length != 1 ? 's' : ''} gesamt | ${widget.aiImagePaths.length} für KI',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nur die markierten (${widget.aiImagePaths.length}) Bilder werden an die KI gesendet (Limitiert auf 3). Alle ${widget.imagePaths.length} werden für die Anzeige genutzt.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Skip button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isAnalyzing ? null : () async {
                      // Proceed without additional info
                      await _analyzeWithAI();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Ohne zusätzliche Infos fortfahren'),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Analyze button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAnalyzing ? null : _analyzeWithAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: _isAnalyzing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('KI analysiert...'),
                            ],
                          )
                        : const Text('Mit KI analysieren'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
