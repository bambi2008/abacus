import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/constants.dart';
import '../services/analytics_service.dart';

enum PurchaseFlowState {
  idle,
  loading,
  pending,
  success,
  cancelled,
  failed,
  unavailable,
}

/// Pro entitlement backed by RevenueCat's verified CustomerInfo.
///
/// No local boolean is treated as proof of purchase. This prevents an expired,
/// refunded, revoked, or otherwise invalid transaction from permanently
/// unlocking Pro. v1 is iOS-only and offers one non-consumable lifetime item.
class SubscriptionProvider extends ChangeNotifier {
  StoreProduct? _lifetimeProduct;
  bool _configured = false;
  bool _isPro = false;

  PurchaseFlowState state = PurchaseFlowState.idle;
  String? errorMessage;

  bool get isPro => _isPro;
  bool get storeAvailable => _configured && _lifetimeProduct != null;
  String get lifetimePrice =>
      _lifetimeProduct?.priceString ?? 'Checking App Store…';

  Future<void> init() async {
    state = PurchaseFlowState.loading;
    notifyListeners();
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.iOS ||
        PurchaseConfig.revenueCatAppleApiKey.isEmpty) {
      state = PurchaseFlowState.unavailable;
      notifyListeners();
      return;
    }

    try {
      await Purchases.configure(
        PurchasesConfiguration(PurchaseConfig.revenueCatAppleApiKey),
      );
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      final results = await Future.wait([
        Purchases.getCustomerInfo(),
        Purchases.getProducts([ProductIds.lifetime]),
      ]);
      _applyCustomerInfo(results[0] as CustomerInfo);
      final products = results[1] as List<StoreProduct>;
      _lifetimeProduct = products
          .where((p) => p.identifier == ProductIds.lifetime)
          .firstOrNull;
      state = _lifetimeProduct == null
          ? PurchaseFlowState.unavailable
          : PurchaseFlowState.idle;
    } catch (e) {
      state = PurchaseFlowState.unavailable;
      errorMessage =
          'Purchases are temporarily unavailable. Please try again later.';
      debugPrint('SubscriptionProvider init failed: $e');
    }
    notifyListeners();
  }

  Future<bool> purchaseLifetime() async {
    final product = _lifetimeProduct;
    if (!_configured || product == null) {
      state = PurchaseFlowState.unavailable;
      errorMessage = 'The Founding Lifetime offer is not available yet.';
      notifyListeners();
      return false;
    }

    state = PurchaseFlowState.loading;
    errorMessage = null;
    notifyListeners();
    AnalyticsService.instance.capture(
      'purchase_attempted',
      properties: {'product_id': ProductIds.lifetime},
    );

    try {
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      );
      _applyCustomerInfo(result.customerInfo);
      if (!_isPro) {
        state = PurchaseFlowState.pending;
        errorMessage =
            'Your purchase is still being confirmed. Pro will unlock automatically when verification finishes.';
        notifyListeners();
        return false;
      }
      state = PurchaseFlowState.success;
      AnalyticsService.instance.capture(
        'purchase_completed',
        properties: {'product_id': ProductIds.lifetime},
      );
      notifyListeners();
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        state = PurchaseFlowState.cancelled;
        errorMessage = null;
      } else if (code == PurchasesErrorCode.paymentPendingError) {
        state = PurchaseFlowState.pending;
        errorMessage =
            'Payment is pending approval. Pro will unlock after the App Store confirms it.';
      } else if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        final info = await Purchases.getCustomerInfo();
        _applyCustomerInfo(info);
        state = _isPro ? PurchaseFlowState.success : PurchaseFlowState.failed;
        errorMessage = _isPro
            ? null
            : 'The App Store reports a previous purchase, but Pro could not be verified. Try Restore Purchases.';
        notifyListeners();
        return _isPro;
      } else {
        state = PurchaseFlowState.failed;
        errorMessage =
            'The purchase could not be completed. Check your App Store purchase history before trying again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      state = PurchaseFlowState.failed;
      errorMessage =
          'The purchase could not be completed. Check your App Store purchase history before trying again.';
      debugPrint('Lifetime purchase failed: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> restore() async {
    if (!_configured) {
      state = PurchaseFlowState.unavailable;
      errorMessage = 'Purchases are not configured in this build.';
      notifyListeners();
      return false;
    }
    state = PurchaseFlowState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      state = _isPro ? PurchaseFlowState.success : PurchaseFlowState.idle;
      errorMessage = _isPro
          ? null
          : 'No previous Pocklume Pro purchase was found for this Apple ID.';
      if (_isPro) AnalyticsService.instance.capture('purchase_restored');
      notifyListeners();
      return _isPro;
    } catch (e) {
      state = PurchaseFlowState.failed;
      errorMessage = 'Restore failed. Check your connection and try again.';
      debugPrint('Restore purchases failed: $e');
      notifyListeners();
      return false;
    }
  }

  void clearMessage() {
    if (state != PurchaseFlowState.loading) state = PurchaseFlowState.idle;
    errorMessage = null;
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo info) {
    _isPro =
        info.entitlements.active[ProductIds.proEntitlement]?.isActive == true;
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
