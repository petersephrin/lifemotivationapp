import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdState {
  Future<InitializationStatus> initialization;
  AdState(this.initialization);

  String get interstitialAdUnitId =>
      Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712' : 'iosadid';

  
}
