import 'dart:core';

import 'package:getting_started/universal_api_key.dart';

class MobileApiKeyProvider implements UniversalApiKeyProvider {
  @override
  String getApiKey() {
    return const String.fromEnvironment('FF_API_KEY', defaultValue: '');
  }
}

UniversalApiKeyProvider getPlatformKeyProvider() => MobileApiKeyProvider();
