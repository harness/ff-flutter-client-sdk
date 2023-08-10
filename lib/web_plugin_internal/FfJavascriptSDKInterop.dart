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
  static const READY = 'ready';
  static const CONNECTED = 'connected';
  static const DISCONNECTED = 'disconnected';
  static const FLAG_LOADED = 'flags loaded';
  static const CACHE_LOADED = 'cache loaded';
  static const CHANGED = 'changed';
  static const ERROR = 'error';
  static const ERROR_AUTH = 'auth error';
  static const ERROR_METRICS = 'metrics error';
  static const ERROR_FETCH_FLAGS = 'fetch flags error';
  static const ERROR_FETCH_FLAG = 'fetch flag error';
  static const ERROR_STREAM = 'stream error';
}


@JS("${JavaScriptSDK.windowReference}.${JavaScriptSDK.initialize}")
external dynamic initialize(
    String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);

@JS('${JavaScriptSDKClient.windowReference}.${JavaScriptSDKClient.on}')
external dynamic on(dynamic eventType, Function callback);
