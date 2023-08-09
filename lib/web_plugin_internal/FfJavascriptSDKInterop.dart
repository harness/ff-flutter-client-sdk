@JS()
library harness_javascript_sdk.js;

import 'package:js/js.dart';

// Represents the window object exposed by the JavaScript SDK
class JavaScriptSDK {
  static const windowReference = 'HarnessFFSDK';
  static const initialize = 'initialize';
  static const event = 'Event';
}

// Represents the Client instance
class JavaScriptSDKClient {
  // Once we've initialized the Client, we set it as a property on the window using
  // this reference
  static const windowReference = 'cfClient';
  static const on = 'on';
  static const off = 'off';
  static const variation = 'variation';
  static const close = 'close';
}

// Represents the events that the JavaScript SDK can emit
class Event {
  static const ready = 'ready';
  static const connected = 'connected';
  static const disconnected = 'disconnected';
  static const flagsLoaded = 'flags loaded';
  static const cacheLoaded = 'cache loaded';
  static const changed = 'changed';
  static const error = 'error';
  static const errorAuth = 'auth error';
  static const errorMetrics = 'metrics error';
  static const errorFetchFlags = 'fetch flags error';
  static const errorFetchFlag = 'fetch flag error';
  static const errorStream = 'stream error';
}


@JS("${JavaScriptSDK.windowReference}.${JavaScriptSDK.initialize}")
external dynamic initialize(
    String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);

@JS('${JavaScriptSDKClient.windowReference}.${JavaScriptSDKClient.on}')
external dynamic on(dynamic eventType, Function callback);
