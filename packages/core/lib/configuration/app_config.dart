import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:universal_platform/universal_platform.dart';

class AppConfig {
  static bool get isDebug => !kReleaseMode;
  bool _isLoaded = false;
  Future<void> init() async {
    String environmentJson = '';
    if (isDebug) {
      environmentJson = 'appsettings.development';
    } else {
      environmentJson = 'appsettings.production';
    }
    final GlobalConfiguration config = await GlobalConfiguration()
        .loadFromAsset('appsettings')
        .then((p) => p.loadFromAsset(environmentJson));

    if (UniversalPlatform.isIOS) {
      //ios would be localhost
    } else if (UniversalPlatform.isAndroid) {
      //android simulator will be 10.0.2.2
      for (final keyValue in GlobalConfiguration().appConfig.entries) {
        if (keyValue.value is String) {
          final String stringValue = keyValue.value as String;
          GlobalConfiguration().updateValue(
              keyValue.key, stringValue.replaceAll('localhost', '10.0.2.2'));
        }
      }
    }
    print('GlobalConfiguration:${config.appConfig.toString()}');
    _isLoaded = true;
  }

  T? getValue<T>(String key, {T? defaultValue}) {
    assert(_isLoaded);
    return GlobalConfiguration().getValue<T>(key) ?? defaultValue;
  }
}
