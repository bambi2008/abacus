import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// On-device-first speech-to-text for a faster alternative to typing an
/// amount/category/note. Lazily initializes the recognizer only when the
/// user actually taps the mic button — never touched during app startup —
/// so an unsupported platform degrades silently instead of risking a
/// startup crash (see the in_app_purchase web-crash lesson documented in
/// docs/technical-architecture.md). Requests on-device recognition where
/// the platform supports it, keeping with the no-cloud-by-default posture;
/// note that iOS's on-device dictation requires the language pack to
/// already be downloaded on the device, so this can still fall back to
/// network recognition on some devices/locales — that's a platform
/// limitation, not something this app controls.
class VoiceInputService {
  VoiceInputService._();
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool? _available;

  /// Whether this platform could plausibly support voice input at all —
  /// checked synchronously so the UI can decide whether to show the mic
  /// button without triggering a permission prompt just to find out
  /// (actual availability, including the mic/speech permission grant, is
  /// only resolved lazily on [listenOnce], same as the OCR camera flow).
  static bool get isSupportedPlatform => !kIsWeb;

  static Future<bool> get isAvailable async {
    if (kIsWeb) return false;
    if (_available != null) return _available!;
    try {
      // initialize() has no guaranteed completion on every device/OS
      // combination — a real-device tester hit the mic button spinning
      // forever, which traced back to this Future never resolving (no
      // error either). Bounded here so the caller always gets an answer.
      _available = await _speech
          .initialize(onError: (e) => debugPrint('VoiceInputService: $e'))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('VoiceInputService: initialize failed or timed out: $e');
      _available = false;
    }
    return _available!;
  }

  /// Listens for a single utterance and returns the recognized transcript,
  /// or null if unavailable, cancelled, or nothing was understood.
  static Future<String?> listenOnce() async {
    if (!await isAvailable) return null;
    String? finalTranscript;
    var done = false;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            finalTranscript = result.recognizedWords;
            done = true;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          onDevice: true,
          partialResults: false,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('VoiceInputService: listen failed: $e');
      return null;
    }

    // listen() returns once recording starts, not once a result arrives —
    // poll briefly for onResult to fire (bounded by listenFor/pauseFor
    // above, plus a small safety margin here).
    for (var i = 0; i < 160 && !done; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await cancel();
    final transcript = finalTranscript?.trim();
    return (transcript == null || transcript.isEmpty) ? null : transcript;
  }

  static Future<void> cancel() async {
    if (_speech.isListening) await _speech.stop();
  }
}
