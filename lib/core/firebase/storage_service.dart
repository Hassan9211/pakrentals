import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  // ── Upload profile photo ───────────────────────────────────────────────────
  static Future<String> uploadProfilePhoto(
      String userId, String localPath) async {
    final file = File(localPath);
    final ref = _storage.ref('users/$userId/profile.jpg');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  // ── Upload listing images ──────────────────────────────────────────────────
  static Future<List<String>> uploadListingImages(
      String listingId, List<String> localPaths) async {
    final urls = <String>[];
    for (int i = 0; i < localPaths.length; i++) {
      final path = localPaths[i];
      if (path.startsWith('http')) {
        // Already a URL — keep as-is
        urls.add(path);
        continue;
      }
      try {
        final file = File(path);
        final ref = _storage
            .ref('listings/$listingId/image_$i.jpg');
        final task = await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final url = await task.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        debugPrint('Image upload error: $e');
      }
    }
    return urls;
  }

  // ── Upload CNIC photos ─────────────────────────────────────────────────────
  static Future<Map<String, String>> uploadCnicPhotos({
    required String userId,
    required String frontPath,
    required String backPath,
  }) async {
    final results = await Future.wait([
      _uploadFile(
        path: frontPath,
        ref: 'users/$userId/cnic_front.jpg',
      ),
      _uploadFile(
        path: backPath,
        ref: 'users/$userId/cnic_back.jpg',
      ),
    ]);
    return {
      'front': results[0],
      'back': results[1],
    };
  }

  // ── Generic file upload ────────────────────────────────────────────────────
  static Future<String> _uploadFile({
    required String path,
    required String ref,
  }) async {
    if (path.startsWith('http')) return path;
    final file = File(path);
    final storageRef = _storage.ref(ref);
    final task = await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  // ── Delete file ────────────────────────────────────────────────────────────
  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Delete file error: $e');
    }
  }
}
