import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  static List<CameraDescription>? _cameras;
  static CameraController? _controller;
  
  static Future<void> initialize() async {
    _cameras = await availableCameras();
  }
  
  static CameraController? get controller => _controller;
  
  static Future<CameraController> initializeCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initialize();
    }
    
    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
    );
    
    await _controller!.initialize();
    return _controller!;
  }
  
  static Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    
    try {
      final image = await _controller!.takePicture();
      
      // Save to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'schnell_verkauf_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(directory.path, fileName);
      
      await File(image.path).copy(filePath);
      
  // Gallery save temporarily disabled due to library API mismatch.
  // TODO: Implement gallery save with a compatible plugin or platform channel.
      
      return filePath;
    } catch (e) {
      return null;
    }
  }
  
  static Future<List<String>> pickImagesFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    List<String> imagePaths = [];
    
    for (var image in images) {
      // Copy to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'schnell_verkauf_${DateTime.now().millisecondsSinceEpoch}_${imagePaths.length}.jpg';
      final filePath = path.join(directory.path, fileName);
      
      await File(image.path).copy(filePath);
      imagePaths.add(filePath);
    }
    
    return imagePaths;
  }
  
  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
