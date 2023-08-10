@JS()
library harness_javascript_sdk.js;

import 'package:js/js.dart';

// Represents the JavaScript SDK global object set by the iife distribution.
@JS('HarnessFFSDK')
class JavaScriptSDK {
  static const windowReference = 'HarnessFFSDK';
  static const initializeFunction = 'initialize';

  external static dynamic initialize(
      String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);
}

// Represents the JavaScript SDK Client instance. Once we've initialized the
// Client, we set it as a property on the window using this reference.
@JS('cfClient')
class JavaScriptSDKClient {
  static const windowReference = 'cfClient';
  static const onFunction = 'on';
  static const offFunction = 'off';
  static const variation = 'variation';
  static const close = 'close';

  external static dynamic on(dynamic eventType, Function callback);
  external static dynamic off(dynamic eventType, Function callback);
}

// Represents the events that the JavaScript SDK Client can emit
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