import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';

@JS('initStripePayment')
external void _jsInitStripePayment(String publishableKey, String clientSecret);

@JS('confirmStripePayment')
external JSPromise<JSString> _jsConfirmStripePayment();

@JS('stripeConfirmCardPayment')
external JSPromise<JSString> _jsConfirmCardPayment(String publishableKey, String clientSecret, String paymentMethodId);

class StripePaymentService {
  static bool _viewRegistered = false;

  /// Register the HtmlElementView factory for the Stripe Payment Element div.
  /// Must be called before the PaymentStep widget is built.
  static void registerViewFactory() {
    if (!kIsWeb || _viewRegistered) return;
    _viewRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      'stripe-payment-element',
      (int viewId) => html.DivElement()
        ..id = 'stripe-payment-element'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  /// Mount the Stripe Payment Element into the registered div.
  /// Call this after the HtmlElementView has been rendered (post-frame).
  static void mountPaymentElement(String publishableKey, String clientSecret) {
    if (!kIsWeb) return;
    _jsInitStripePayment(publishableKey, clientSecret);
  }

  /// Confirm a card payment client-side using a saved payment method ID.
  /// Handles 3DS inline if required. Returns null on success, or an error string.
  static Future<String?> confirmCardPayment(String publishableKey, String clientSecret, String paymentMethodId) async {
    if (!kIsWeb) return 'Payment only available on web.';
    try {
      final result = await _jsConfirmCardPayment(publishableKey, clientSecret, paymentMethodId).toDart;
      final error = result.toDart;
      return error.isEmpty ? null : error;
    } catch (e) {
      return 'Payment failed. Please try again.';
    }
  }

  /// Confirm the payment. Returns null on success, or an error message string.
  static Future<String?> confirmPayment() async {
    if (!kIsWeb) return 'Payment only available on web.';
    try {
      final result = await _jsConfirmStripePayment().toDart;
      final error = result.toDart;
      return error.isEmpty ? null : error;
    } catch (e) {
      return 'Payment failed. Please try again.';
    }
  }
}
