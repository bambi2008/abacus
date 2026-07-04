import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../config/constants.dart';

/// Anonymous, aggregate funnel analytics — exists to validate (or
/// invalidate) the conversion-rate assumptions baked into
/// docs/financial-model-year1-3.xlsx. Never send expense amounts, category
/// names, or notes — event names only. No-ops until a real PostHog project
/// key is supplied via --dart-define=POSTHOG_API_KEY=..., so the app works
/// identically without one. Respects the opt-out toggle in Settings
/// (SettingsKeys.analyticsEnabled, default on).
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  Box? _settings;
  bool _ready = false;

  Future<void> init() async {
    _settings = Hive.box(HiveBoxes.settings);
    if (RemoteConfig.posthogApiKey.isEmpty) return;
    try {
      final config = PostHogConfig(RemoteConfig.posthogApiKey)
        ..host = RemoteConfig.posthogHost
        ..captureApplicationLifecycleEvents = true;
      await Posthog().setup(config);
      _ready = true;
    } catch (e) {
      debugPrint('AnalyticsService: setup failed, disabling analytics: $e');
    }
  }

  bool get enabled => _settings?.get(SettingsKeys.analyticsEnabled, defaultValue: true) as bool? ?? true;

  Future<void> setEnabled(bool value) async {
    await _settings?.put(SettingsKeys.analyticsEnabled, value);
  }

  void capture(String event, {Map<String, Object>? properties}) {
    if (!_ready || !enabled) return;
    Posthog().capture(eventName: event, properties: properties);
  }
}
