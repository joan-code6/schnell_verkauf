import 'dart:io';
import 'package:flutter/material.dart';
import 'additional_info_screen.dart';

/// Screen where the user chooses up to 3 images that will be sent to the AI.
/// All images (any number) can later still be uploaded to Kleinanzeigen, but
/// only the selected (max 3) go through the Gemini analyze step.
class SelectAIImagesScreen extends StatefulWidget {
  final List<String> allImagePaths;
  const SelectAIImagesScreen({super.key, required this.allImagePaths});

  @override
  State<SelectAIImagesScreen> createState() => _SelectAIImagesScreenState();
}

class _SelectAIImagesScreenState extends State<SelectAIImagesScreen> {
  // Maintain a set of selected paths (max 3 for Gemini API)
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    // If there are 3 or fewer images, preselect them so user can just continue.
    if (widget.allImagePaths.length <= 3) {
      _selected.addAll(widget.allImagePaths);
    }
  }

  void _toggle(String path) {
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        if (_selected.length < 3) {
          _selected.add(path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximal 3 Bilder für die KI auswählen'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _proceed() {
    // If user hasn't chosen anything (e.g. skipped), fall back to first up to 3 automatically
    if (_selected.isEmpty) {
      _selected.addAll(widget.allImagePaths.take(3));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdditionalInfoScreen(
          imagePaths: widget.allImagePaths, // all images for final ad
          aiImagePaths: _selected.toList(), // only these go to AI
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilder für KI auswählen'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,16,16,4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bilder für die KI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Wähle bis zu 3 aussagekräftige Fotos aus. Nur diese werden an die KI geschickt. Alle ${widget.allImagePaths.length} ausgewählten Fotos nutzt du später für deine Kleinanzeige.',
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tipp: Vorderseite, Detail / Zustand, Gesamtansicht.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.allImagePaths.length,
              itemBuilder: (context, index) {
                final path = widget.allImagePaths[index];
                final selected = _selected.contains(path);
                return GestureDetector(
                  onTap: () => _toggle(path),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: AnimatedScale(
                          scale: selected ? 1 : 0.9,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? Colors.orange : Colors.black45,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 2),
                            ),
                            width: 28,
                            height: 28,
                            child: Icon(
                              selected ? Icons.check : Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Weiter'),
            ),
          ),
        ],
      ),
    );
  }
}
