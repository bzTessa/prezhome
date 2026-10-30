import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Compra de Pro con RevenueCat. El plan real lo pone el servidor
/// (función `revenuecat-webhook` → `subscriptions.plan`); aquí solo se compra
/// y se restaura. Las claves públicas del SDK llegan al compilar:
/// `--dart-define=REVENUECAT_IOS_KEY=appl_… --dart-define=REVENUECAT_ANDROID_KEY=goog_…`
class ProPurchases {
  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  /// Permiso de RevenueCat que da Pro (el mismo que mira el servidor).
  static const entitlement = 'pro';

  static String get _key => kIsWeb
      ? ''
      : Platform.isIOS || Platform.isMacOS
      ? _iosKey
      : Platform.isAndroid
      ? _androidKey
      : '';

  /// Sin clave (o en web/escritorio) no se puede comprar todavía.
  static bool get available => _key.isNotEmpty;

  /// Configura el SDK con el usuario de Supabase como app_user_id, que es
  /// como el servidor sabe a qué hogar dar Pro.
  static Future<void> _ready() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw StateError('Inicia sesión para continuar.');
    if (!await Purchases.isConfigured) {
      await Purchases.configure(PurchasesConfiguration(_key)..appUserID = uid);
    } else if (await Purchases.appUserID != uid) {
      await Purchases.logIn(uid);
    }
  }

  /// Opciones de pago de la oferta actual (mensual, anual…).
  static Future<List<Package>> packages() async {
    await _ready();
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? const [];
  }

  /// Compra. Devuelve true si ya tiene Pro y false si la persona cancela.
  static Future<bool> buy(Package package) async {
    await _ready();
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _isPro(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// Restaura compras de esta cuenta de la tienda. True si hay Pro.
  static Future<bool> restore() async {
    await _ready();
    return _isPro(await Purchases.restorePurchases());
  }

  static bool _isPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlement);
}
