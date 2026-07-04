import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/constants.dart';
import '../services/analytics_service.dart';

class OnboardingProvider extends ChangeNotifier {
  late Box _settings;

  void load() {
    _settings = Hive.box(HiveBoxes.settings);
  }

  bool get hasOnboarded => _settings.get(SettingsKeys.hasOnboarded, defaultValue: false) as bool;

  Future<void> complete() async {
    await _settings.put(SettingsKeys.hasOnboarded, true);
    AnalyticsService.instance.capture('onboarding_completed');
    notifyListeners();
  }
}
