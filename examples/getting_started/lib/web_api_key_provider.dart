import 'dart:js' as js;
import 'package:getting_started/universal_api_key.dart';

class WebApiKeyProvider implements UniversalApiKeyProvider {
  @override
  String getApiKey() {
    return js.context['FF_API_KEY'] ?? '';
  }
}

UniversalApiKeyProvider getPlatformKeyProvider() => WebApiKeyProvider();
