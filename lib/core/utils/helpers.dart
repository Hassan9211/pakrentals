import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';

String formatPrice(dynamic price) {
  if (price == null) return 'PKR 0';
  final num = double.tryParse(price.toString()) ?? 0;
  final formatter = NumberFormat('#,##0', 'en_US');
  return 'PKR ${formatter.format(num)}';
}

String formatDate(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('MMM d, yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}

String formatDateTime(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  } catch (_) {
    return dateStr;
  }
}

String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  // Already a full URL
  if (path.startsWith('http')) return path;
  // Local file path from image picker (starts with / on Android/iOS)
  if (path.startsWith('/') || path.startsWith('file://')) return path;
  // Relative path from backend storage
  return '$kStorageUrl/$path';
}

/// Returns true if the image path is a local device file
bool isLocalFile(String path) {
  return path.startsWith('/') || path.startsWith('file://');
}

String getInitials(String? name) {
  if (name == null || name.isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name[0].toUpperCase();
}

void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

int calculateDays(DateTime start, DateTime end) {
  return end.difference(start).inDays + 1;
}

String bookingStatusLabel(String status) {
  switch (status) {
    case 'pending': return 'Pending';
    case 'approved': return 'Approved';
    case 'rejected': return 'Rejected';
    case 'paid': return 'Paid';
    case 'active': return 'Active';
    case 'completed': return 'Completed';
    case 'cancelled': return 'Cancelled';
    default: return status;
  }
}

Color bookingStatusColor(String status) {
  switch (status) {
    case 'pending': return const Color(0xFFF59E0B);
    case 'approved': return const Color(0xFF3B82F6);
    case 'rejected': return const Color(0xFFEF4444);
    case 'paid': return const Color(0xFF8B5CF6);
    case 'active': return const Color(0xFF10B981);
    case 'completed': return const Color(0xFF10B981);
    case 'cancelled': return const Color(0xFF6B7280);
    default: return const Color(0xFF6B7280);
  }
}
