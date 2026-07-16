/// Analytics are intentionally disabled for the privacy-first iOS launch.
/// Keeping this no-op façade lets feature code retain named product events
/// without shipping an analytics SDK or transmitting usage data. A future
/// analytics release requires a new privacy review and policy update.
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  Future<void> init() async {}

  void capture(String event, {Map<String, Object>? properties}) {}
}
