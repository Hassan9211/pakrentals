import 'dart:io';
import '../services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  // ── Upload profile photo ───────────────────────────────────────────────────
  static Future<String> uploadProfilePhoto(
      String userId, String localPath) async {
    final file = File(localPath);
    final url = await CloudinaryService.uploadImage(file);
    return url ?? localPath;
  }

  // ── Upload listing images ──────────────────────────────────────────────────
  static Future<List<String>> uploadListingImages(
      String listingId, List<String> localPaths) async {
    final files = localPaths
        .where((p) => !p.startsWith('http'))
        .map((p) => File(p))
        .toList();
    
    final urls = await CloudinaryService.uploadMultipleImages(files);
    
    // Add existing http urls back
    final existingUrls = localPaths.where((p) => p.startsWith('http')).toList();
    return [...existingUrls, ...urls];
  }

  // ── Upload CNIC photos ─────────────────────────────────────────────────────
  static Future<Map<String, String>> uploadCnicPhotos({
    required String userId,
    required String frontPath,
    required String backPath,
  }) async {
    final results = await Future.wait([
      _uploadFile(path: frontPath),
      _uploadFile(path: backPath),
    ]);
    return {
      'front': results[0],
      'back': results[1],
    };
  }

  // ── Generic file upload ────────────────────────────────────────────────────
  static Future<String> _uploadFile({
    required String path,
  }) async {
    if (path.startsWith('http')) return path;
    final file = File(path);
    final url = await CloudinaryService.uploadImage(file);
    return url ?? path;
  }

  // ── Delete file (Cloudinary delete requires API secret, skipping for now) ──
  static Future<void> deleteFile(String url) async {
    // For now we don't delete from Cloudinary to keep it simple (unsigned)
    debugPrint('Cloudinary delete requested for $url (not implemented)');
  }
}
