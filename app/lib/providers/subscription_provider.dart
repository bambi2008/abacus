import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/constants.dart';
import '../services/analytics_service.dart';

/// Entitlement state for Pro features, backed by real `in_app_purchase`
/// once App Store Connect / Play Console products matching [ProductIds]
/// exist. Until then [products] stays empty and [purchase] falls back to a
/// debug-only local mock so the paywall flow stays testable — gated on
/// [kDebugMode], never runs in a release build.
class SubscriptionProvider extends ChangeNotifier {
  late Box _settings;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  List<ProductDetails> products = [];
  bool storeAvailable = false;

  void load() {
    _settings = Hive.box(HiveBoxes.settings);
  }

  Future<void> init() async {
    // in_app_purchase has no Flutter Web platform implementation — there's
    // no App Store/Play Store checkout on web at all, so
    // InAppPurchasePlatform.instance is never registered there and throws
    // a LateInitializationError the moment isAvailable() is called. Skip
    // entirely on web; purchase() still works via its kDebugMode mock so
    // the paywall flow stays testable in a web preview.
    if (kIsWeb) {
      notifyListeners();
      return;
    }
    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final response = await _iap.queryProductDetails({ProductIds.monthly, ProductIds.lifetime});
        products = response.productDetails;
        _purchaseSubscription = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (Object _) {});
      }
    } catch (e) {
      debugPrint('SubscriptionProvider: IAP unavailable on this platform: $e');
    }
    notifyListeners();
  }

  bool get isPro => _settings.get(SettingsKeys.isPro, defaultValue: false) as bool;

  ProductDetails? productFor(String productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<void> purchase(String productId) async {
    AnalyticsService.instance.capture('purchase_attempted', properties: {'product_id': productId});
    final product = productFor(productId);
    if (product == null) {
      if (kDebugMode) {
        await _settings.put(SettingsKeys.isPro, true);
        notifyListeners();
      }
      return;
    }
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restore() async {
    if (storeAvailable) {
      await _iap.restorePurchases();
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        await _settings.put(SettingsKeys.isPro, true);
        AnalyticsService.instance.capture(
          purchase.status == PurchaseStatus.restored ? 'purchase_restored' : 'purchase_completed',
          properties: {'product_id': purchase.productID},
        );
        notifyListeners();
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
