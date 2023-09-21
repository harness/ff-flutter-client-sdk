import 'universal_api_key_provider.dart' if (dart.library.html) 'package:getting_started/web_api_key_provider.dart' if (dart.library.io) 'package:getting_started/mobile_api_key_provider.dart';


abstract class UniversalApiKeyProvider {
  String getApiKey();

  factory UniversalApiKeyProvider() => getPlatformKeyProvider();
}
