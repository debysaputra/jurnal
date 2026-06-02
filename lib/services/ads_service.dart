import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;

  // Production Ad Unit IDs milik MyJurnal.
  // Catatan: saat dev/test JANGAN klik iklan sendiri agar akun AdMob tidak
  // dibanned. Pakai test device ID atau toggle _useTestAds = true di bawah.
  static const bool _useTestAds = false;

  static String get bannerUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // Banner unit ID milik MyJurnal
    return 'ca-app-pub-4983939936970212/9910340720';
  }

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }
}
