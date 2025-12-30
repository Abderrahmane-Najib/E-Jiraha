import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_service.dart';

/// Service for handling image capture and upload to Firebase Storage
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseService().storage;

  /// Pick image from camera
  Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage and return download URL
  /// [folder] - Storage folder (e.g., 'patients', 'consents')
  /// [fileName] - Name for the file
  /// [file] - XFile from image picker
  Future<String?> uploadImage({
    required String folder,
    required String fileName,
    required XFile file,
  }) async {
    try {
      final ref = _storage.ref().child(folder).child(fileName);
      final uploadTask = await ref.putFile(
        File(file.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Pick and upload CIN image (front or back)
  /// Returns the download URL or null if cancelled/failed
  Future<String?> pickAndUploadCIN({
    required String patientId,
    required bool isFront,
    bool fromCamera = true,
  }) async {
    final XFile? image = fromCamera
        ? await pickFromCamera()
        : await pickFromGallery();

    if (image == null) return null;

    final side = isFront ? 'front' : 'back';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'cin_${side}_${patientId}_$timestamp.jpg';

    return await uploadImage(
      folder: 'patients/$patientId/cin',
      fileName: fileName,
      file: image,
    );
  }

  /// Pick and upload consent form image
  Future<String?> pickAndUploadConsent({
    required String caseId,
    required String type, // 'surgery' or 'anesthesia'
    bool fromCamera = true,
  }) async {
    final XFile? image = fromCamera
        ? await pickFromCamera()
        : await pickFromGallery();

    if (image == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'consent_${type}_${caseId}_$timestamp.jpg';

    return await uploadImage(
      folder: 'cases/$caseId/consents',
      fileName: fileName,
      file: image,
    );
  }

  /// Pick and upload document image
  Future<String?> pickAndUploadDocument({
    required String caseId,
    required String documentName,
    bool fromCamera = true,
  }) async {
    final XFile? image = fromCamera
        ? await pickFromCamera()
        : await pickFromGallery();

    if (image == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${documentName}_${caseId}_$timestamp.jpg';

    return await uploadImage(
      folder: 'cases/$caseId/documents',
      fileName: fileName,
      file: image,
    );
  }
}
