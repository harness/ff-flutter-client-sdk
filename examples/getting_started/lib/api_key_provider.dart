import 'dart:js' as js;


abstract class ApiKeyProvider {
  String getApiKey();
}

class WebApiKeyProvider implements ApiKeyProvider {
  @override
  String getApiKey() {
    return js.context['FF_API_KEY'] ?? '';
  }
}

class MobileApiKeyProvider implements ApiKeyProvider {
  @override
  String getApiKey() {
    return const String.fromEnvironment('FF_API_KEY', defaultValue: '');
  }
}
