import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/receipt_scan_result.dart';

/// On-device receipt OCR — Apple's Vision framework on iOS
/// (ios/Runner/ReceiptOcrPlugin.swift), Google ML Kit on Android
/// (android/.../ReceiptOcrPlugin.kt). Purely an entry-speed assist for
/// Pocklume's manual-first core loop — it never syncs to a bank, never sends
/// the photo anywhere (recognition runs entirely on-device), and every
/// extracted field still lands in the normal log-expense sheet for the user
/// to confirm or edit before it becomes a real Expense. See
/// docs/technical-architecture.md's "Receipt OCR" section.
class ReceiptOcrService {
  static const _channel = MethodChannel('com.pocklume.app/receipt_ocr');

  /// Checked so the UI can hide the "Scan receipt" entry point entirely on
  /// platforms with no native recognition plugin wired up (web, desktop).
  static bool get isAvailable =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Runs on-device text recognition on the photo at [imagePath] and returns
  /// a best-guess amount/vendor/date, or null if recognition produced
  /// nothing usable or the platform channel isn't available (e.g. running on
  /// a platform/simulator without the native plugin) — callers should treat
  /// null exactly like "no scan happened" and fall back to blank manual entry.
  static Future<ReceiptScanResult?> scan(String imagePath) async {
    if (!isAvailable) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'recognizeText',
        {'path': imagePath},
      );
      final lines =
          (result?['lines'] as List?)?.cast<String>() ?? const <String>[];
      if (lines.isEmpty) return null;
      final parsed = parseReceiptText(lines);
      return parsed.isEmpty ? null : parsed;
    } on PlatformException catch (e) {
      debugPrint('ReceiptOcrService: recognition failed: $e');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
