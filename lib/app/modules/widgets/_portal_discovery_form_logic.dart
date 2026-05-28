import 'package:flutter/material.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import '_discovery_form_constants.dart';

// Pure data-manipulation helpers for PortalDiscoveryForm._State.
// No widget tree — all methods are static.
class DiscoveryFormLogic {
  DiscoveryFormLogic._();
  // Copies recognised prefill keys into [data] via putIfAbsent.
  static void applyPrefill(Map<String, dynamic> data, Map<String, dynamic> prefill) {
    const mapping = {
      'business_website': 'SITE_URL',
      'color_primary': 'COLOR_PRIMARY',
      'color_secondary': 'COLOR_SECONDARY',
      'font_primary': 'FONT_PRIMARY',
      'phone': 'PHONE',
      'city': 'CITY',
      'state': 'STATE',
      'zip': 'ZIP',
      'tagline': 'TAGLINE',
      'logo_url': 'LOGO_URL',
    };
    for (final entry in mapping.entries) {
      final val = prefill[entry.key];
      if (val != null && val.toString().isNotEmpty) {
        data.putIfAbsent(entry.value, () => val);
      }
    }
  }

  // Builds a diff map: prefillKey → { was, now } for every field that changed.
  static Map<String, dynamic> computeChanges(Map<String, dynamic> data, PortalQuote quote) {
    const prefillMapping = {
      'business_website': 'SITE_URL',
      'color_primary': 'COLOR_PRIMARY',
      'color_secondary': 'COLOR_SECONDARY',
      'font_primary': 'FONT_PRIMARY',
      'phone': 'PHONE',
      'city': 'CITY',
      'state': 'STATE',
      'zip': 'ZIP',
      'tagline': 'TAGLINE',
      'logo_url': 'LOGO_URL',
    };
    final prefill = quote.discoveryPrefill;
    final changes = <String, dynamic>{};
    for (final entry in prefillMapping.entries) {
      final was = (prefill[entry.key] ?? '').toString();
      final now = (data[entry.value] ?? '').toString();
      if (was.isNotEmpty && was != now) {
        changes[entry.key] = {'was': was, 'now': now};
      }
    }
    return changes;
  }

  // Hydrates all text controllers and hours map from [data].
  static void populateControllers({
    required Map<String, dynamic> data,
    required Map<String, Map<String, dynamic>> hours,
    required TextEditingController shortName,
    required TextEditingController colorPri,
    required TextEditingController colorSec,
    required TextEditingController colorAcc,
    required TextEditingController colorSurf,
    required TextEditingController colorOn,
    required TextEditingController fontPri,
    required TextEditingController fontSec,
    required TextEditingController threeWords,
    required TextEditingController celebrity,
    required TextEditingController inspoUrls,
    required TextEditingController targetCust,
    required TextEditingController phone,
    required TextEditingController street,
    required TextEditingController city,
    required TextEditingController stateCtrl,
    required TextEditingController zip,
    required TextEditingController country,
    required TextEditingController siteUrl,
    required TextEditingController seoTitle,
    required TextEditingController seoDesc,
    required TextEditingController fromEmail,
    required TextEditingController instagram,
    required TextEditingController facebook,
    required TextEditingController tiktok,
    required TextEditingController youtube,
  }) {
    String s(String k) => (data[k] as String?) ?? '';
    shortName.text = s('SHORT_NAME');
    colorPri.text = s('COLOR_PRIMARY');
    colorSec.text = s('COLOR_SECONDARY');
    colorAcc.text = s('COLOR_ACCENT');
    colorSurf.text = s('COLOR_SURFACE');
    colorOn.text = s('COLOR_ON_SURFACE');
    fontPri.text = s('FONT_PRIMARY');
    fontSec.text = s('FONT_SECONDARY');
    final bb = (data['brand_brief'] as Map<String, dynamic>?) ?? {};
    threeWords.text = (bb['three_words'] as String?) ?? '';
    celebrity.text = (bb['celebrity'] as String?) ?? '';
    inspoUrls.text = (bb['inspo_urls'] as String?) ?? '';
    targetCust.text = (bb['target_customer'] as String?) ?? '';
    phone.text = s('PHONE');
    street.text = s('STREET');
    city.text = s('CITY');
    stateCtrl.text = s('STATE');
    zip.text = s('ZIP');
    country.text = s('COUNTRY');
    siteUrl.text = s('SITE_URL');
    seoTitle.text = s('SEO_TITLE');
    seoDesc.text = s('SEO_DESCRIPTION');
    fromEmail.text = s('FROM_EMAIL');
    instagram.text = s('INSTAGRAM_URL');
    facebook.text = s('FACEBOOK_URL');
    tiktok.text = s('TIKTOK_URL');
    youtube.text = s('YOUTUBE_URL');

    final sh = (data['HOURS_JSON'] as Map<String, dynamic>?) ?? {};
    for (final d in discoveryDays) {
      hours[d] = {
        'open': (sh[d.toLowerCase()]?['open'] as String?) ?? '9:00 AM',
        'close': (sh[d.toLowerCase()]?['close'] as String?) ?? '5:00 PM',
        'closed': (sh[d.toLowerCase()]?['closed'] as bool?) ?? false,
      };
    }
  }
}
