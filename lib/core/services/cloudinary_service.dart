import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String _cloudName = 'dqbkvdpwu';
  static const String _apiKey = '575672746915137';
  static const String _apiSecret = 'y8VFg4Q9mn9rAWc20WO_nAGiu4w';

  static final Dio _dio = Dio();

  static Future<String?> uploadImage(File file) async {
    try {
      final String url =
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 1. Generate Signature
      // format: "timestamp=1234567890<API_SECRET>"
      final String toSign = 'timestamp=$timestamp$_apiSecret';
      final String signature = sha1.convert(utf8.encode(toSign)).toString();

      debugPrint('Cloudinary: Starting signed upload to $url');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'api_key': _apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      final response = await _dio.post(url, data: formData);

      debugPrint('Cloudinary Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Cloudinary Dio Error: ${e.response?.data ?? e.message}');
      } else {
        debugPrint('Cloudinary General Error: $e');
      }
      return null;
    }
  }

  static Future<List<String>> uploadMultipleImages(List<File> files) async {
    List<String> urls = [];
    for (var file in files) {
      final url = await uploadImage(file);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}
