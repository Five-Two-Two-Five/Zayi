import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LogoService {
  /// Processes a picked image file: decodes it, converts to PNG, 
  /// and saves it to the app's document directory.
  static Future<String?> processAndSaveLogo(String inputPath) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      
      // Decode image (supports many formats: JPG, PNG, GIF, WEBP, TIFF, etc.)
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Optional: Resize if the image is too large (e.g., max width 300px)
      if (image.width > 300) {
        image = img.copyResize(image, width: 300);
      }

      // Encode as PNG (highest compatibility for PDF rendering)
      final pngBytes = img.encodePng(image);

      // Get app directory to save the processed logo
      final directory = await getApplicationDocumentsDirectory();
      final logoDir = Directory(path.join(directory.path, 'logos'));
      if (!await logoDir.exists()) {
        await logoDir.create(recursive: true);
      }

      final fileName = 'business_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputPath = path.join(logoDir.path, fileName);
      
      // Save the file
      await File(outputPath).writeAsBytes(pngBytes);

      return outputPath;
    } catch (e) {
      // Log error internally
      return null;
    }
  }

  /// Deletes an existing logo file to clean up storage.
  static Future<void> deleteLogo(String? filePath) async {
    if (filePath == null) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Log error internally
    }
  }
}
