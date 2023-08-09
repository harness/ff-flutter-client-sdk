@JS()
library harness_javascript_sdk.js;

import 'package:js/js.dart';

class SDKReferences {
  static const window = 'HarnessFFSDK';
  static const initialize = 'initialize';
  static const event = 'Event';
}

class ClientReferences {
  static const window = 'cfClient';
  static const on = 'on';
  static const off = 'off';
  static const variation = 'variation';
  static const close = 'close';
}

// Usage in annotations:
@JS("${SDKReferences.window}.${SDKReferences.initialize}")
external dynamic initialize(
    String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);

@JS('${ClientReferences.window}.${ClientReferences.on}')
external dynamic on(
    String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);
