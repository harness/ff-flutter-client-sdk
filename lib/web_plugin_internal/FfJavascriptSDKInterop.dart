@JS()
library harness_javascript_sdk.js;

import 'package:js/js.dart';

// Represents the JavaScript SDK global object set by the iife distribution.
@JS(JavaScriptSDK.windowReference)
class JavaScriptSDK {
  static const windowReference = 'HarnessFFSDK';
  static const initializeFunction = 'initialize';

  external static dynamic initialize(
      String apiKey, Object target, Options options);
}

// Represents the JavaScript SDK Client instance. Once we've initialized the
// Client, we set it as a property on the window using this reference.
@JS(JavaScriptSDKClient.windowReference)
class JavaScriptSDKClient {
  static const windowReference = 'cfClient';
  static const onFunction = 'on';
  static const offFunction = 'off';
  static const variationFunction = 'variation';
  static const closeFunction = 'close';

  external static dynamic on(dynamic eventType, Function callback);
  external static dynamic off(dynamic eventType, Function callback);
  external static dynamic variation(
      dynamic flagIdentifier, dynamic defaultValue, bool withDebug);
  external static dynamic close();
}

// Represents the events that the JavaScript SDK Client can emit
class Event {
  static const READY = 'ready';
  static const CONNECTED = 'connected';
  static const STOPPED = 'stopped';
  static const DISCONNECTED = 'disconnected';
  static const FLAG_LOADED = 'flags loaded';
  static const CACHE_LOADED = 'cache loaded';
  static const CHANGED = 'changed';
  static const POLLING = 'polling';
  static const POLLING_STOPPED = 'polling stopped';
  static const POLLING_CHANGED = 'polling changed';
  static const ERROR = 'error';
  static const ERROR_AUTH = 'auth error';
  static const ERROR_METRICS = 'metrics error';
  static const ERROR_FETCH_FLAGS = 'fetch flags error';
  static const ERROR_FETCH_FLAG = 'fetch flag error';
  static const ERROR_STREAM = 'stream error';
}

@JS()
@anonymous
/// The options payload for [JavaScriptSDK.initialize].
class Options {
  external String get baseUrl;
  external String get eventUrl;
  external int get pollingInterval;
  external bool get streamEnabled;
  external bool get pollingEnabled;
  external bool get debug;

  external factory Options(
      {String baseUrl, String eventUrl, int pollingInterval, bool streamEnabled, bool pollingEnabled, bool debug});
}

@JS()
@anonymous
/// The payload from [Event.CHANGED].
class FlagChange {
  external String get flag;
  external String get identifier;
  external String get value;
  external String get kind;
}

@JS()
@anonymous
/// The payload from [JavaScriptSDKClient.variation].
class VariationResult {
  external dynamic get value;
  external bool get isDefaultValue;
}
