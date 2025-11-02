import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'edit_product_screen.dart';

class AdditionalInfoScreen extends StatefulWidget {
  final List<String> imagePaths;
  
  const AdditionalInfoScreen({
    super.key,
    required this.imagePaths,
  });

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  bool _isAnalyzing = false;
  final TextEditingController _additionalInfoController = TextEditingController();
  
  // Preset phrases for common product conditions
  final List<String> _presets = [
    'Neuwertig',
    'Sehr guter Zustand',
    'Guter Zustand',
    'Gebraucht',
    'Defekt',
    'Für Bastler',
    'Gebrauchsspuren',
    'Originalverpackung',
    'Ohne Zubehör',
    'Vintage',
    'Sammlerstück',
    'Funktionsfähig',
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
    if (widget.imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens ein Foto hinzufügen')),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final additionalInfo = _additionalInfoController.text.trim();
      final productData = await AIService.analyzeImages(widget.imagePaths, additionalInfo: additionalInfo);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditProductScreen(productData: productData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Fehler bei der Analyse: $e';
        
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Zusätzliche Informationen'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    elevation: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Zusätzliche Informationen für die KI',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Beschreiben Sie den Zustand oder besondere Eigenschaften des Produkts. Diese Informationen helfen der KI bei einer genaueren Analyse.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.4,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Text input field
                  Card(
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produktbeschreibung',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _additionalInfoController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Beschreiben Sie den Zustand oder besondere Eigenschaften...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Preset buttons
                  Card(
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schnellauswahl',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tippen Sie auf die Begriffe, um sie hinzuzufügen:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _presets.map((preset) {
                              return _buildPresetChip(preset);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Photos summary
                  Card(
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.photo_library_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.imagePaths.length} Foto${widget.imagePaths.length != 1 ? 's' : ''} ausgewählt',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Diese Fotos werden zusammen mit Ihren zusätzlichen Informationen an die KI gesendet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeWithAI,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.smart_toy_rounded, size: 24),
              label: Text(_isAnalyzing ? 'Analysiere...' : 'KI-Analyse starten'),
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
        ],
      ),
    );
  }

  Widget _buildPresetChip(String preset) {
    return InkWell(
      onTap: () => _addPresetText(preset),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
          ),
        ),
        child: Text(
          preset,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
