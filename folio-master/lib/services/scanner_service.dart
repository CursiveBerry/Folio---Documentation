import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ScannerService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<File>> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    return images.map((xFile) => File(xFile.path)).toList();
  }

  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image != null ? File(image.path) : null;
  }

  Future<File> saveImageToPermanentStorage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final folioDir = Directory(p.join(directory.path, 'scans'));

    if (!await folioDir.exists()) {
      await folioDir.create(recursive: true);
    }

    final String fileName = 'FOLIO_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final File permanentImage = await image.copy(p.join(folioDir.path, fileName));
    return permanentImage;
  }

  // FIXED OCR Text Extraction Logic
  Future<String> getSmartName(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract and combine all recognized text blocks to lowercase
      final String fullText = recognizedText.blocks
          .map((block) => block.text)
          .join(' ')
          .toLowerCase();

      if (fullText.isEmpty) return 'Scanned Document';

      if (fullText.contains('invoice') || fullText.contains('bill') || fullText.contains('total') || fullText.contains('amount')) {
        if (fullText.contains('amazon')) return 'Amazon_Invoice';
        if (fullText.contains('google')) return 'Google_Receipt';
        if (fullText.contains('apple')) return 'Apple_Invoice';
        return 'Commercial_Invoice';
      }

      if (fullText.contains('passport') || fullText.contains('republic')) return 'Passport_Document';
      if (fullText.contains('license') || fullText.contains('driving')) return 'ID_DriverLicense';
      if (fullText.contains('resume') || fullText.contains('curriculum')) return 'Resume_CV';

      // Fallback: Use the first recognized line as the file title if meaningful
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          String lineText = line.text.trim();
          if (lineText.length > 3 && lineText.length < 25) {
            // Clean characters invalid for names
            return lineText.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
          }
        }
      }
    } catch (_) {
      // Fallback on ML failure gracefully
    }

    return 'Document_${DateTime.now().second}';
  }
}