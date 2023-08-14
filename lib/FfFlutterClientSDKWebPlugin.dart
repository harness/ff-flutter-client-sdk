@JS()
library ff_web_plugin;

import 'dart:async';
import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'CfClient.dart';
import 'web_plugin_internal//FfJavascriptSDKInterop.dart';

@JS('window')
external dynamic get window;

class FfFlutterClientSdkWebPlugin {
  final log = Logger('FfFlutterClientSdkWebPluginLogger');
  // The method calls that the core Flutter SDK can make
  static const _initializeMethodCall = 'initialize';
  static const _registerEventsListenerMethodCall = 'registerEventsListener';
  static const _variationMethodCall = 'variation';

  // Used to emit JavaScript SDK events to the host MethodChannel
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  // Store registered events and their function references, so that they can
  // be removed later.
  static Map<String, List<Function>> _registeredEventListeners = {
    Event.READY: [],
    Event.CONNECTED: [],
    Event.DISCONNECTED: [],
    Event.FLAG_LOADED: [],
    Event.CACHE_LOADED: [],
    Event.CHANGED: [],
    Event.ERROR: [],
    Event.ERROR_AUTH: [],
    Event.ERROR_METRICS: [],
    Event.ERROR_FETCH_FLAGS: [],
    Event.ERROR_FETCH_FLAG: [],
    Event.ERROR_STREAM: []
  };
  // Used to send JavaScript SDK events to the Flutter
  // SDK Code.
  static late MethodChannel _hostChannel;

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'ff_flutter_client_sdk',
      const StandardMethodCodec(),
      registrar,
    );

    _hostChannel = MethodChannel(
      'cf_flutter_host',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = FfFlutterClientSdkWebPlugin();
    channel.setMethodCallHandler(pluginInstance._handleMethodCall);
  }

  /// Handles method calls over the [MethodChannel] for this plugin
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case _initializeMethodCall:
        return await _invokeInitialize(call);
      case _registerEventsListenerMethodCall:
        _registerJsSDKStreamListeners();
        break;
    }
  }

  Future<bool> _invokeInitialize(MethodCall call) async {
    final String apiKey = call.arguments['apiKey'];
    final Object target = _mapToJsObject(call.arguments['target']);
    final Object options = _mapToJsObject(call.arguments['configuration']);
    final response = JavaScriptSDK.initialize(apiKey, target, options);

    // The JavaScript SDK returns the client instance, whether or not
    // the initialization was successful. We set a reference to it on
    // the global window, and then we can listen if initialization was
    // successful or not.
    setProperty(window, JavaScriptSDKClient.windowReference, response);

    // Used to return the result of initialize after the JavaScript SDK
    // emits either a READY or ERROR event.
    return _waitForInitializationResult();
  }

  Future<bool> _waitForInitializationResult() {
    final _initializationResult = Completer<bool>();

    // Callback for the JavaScript SDK's READY event. It returns a list of
    // evaluations, but we don't need them in this plugin.
    final readyCallback = ([_]) {
      // While we shouldn't attempt to complete this completer more than once,
      // this is a defensive check and log if it is attempted.
      if (!_initializationResult.isCompleted) {
        _initializationResult.complete(true);
      } else {
        log.info(
            'JavaScript SDK success response already handled. Ignoring subsequent response.');
      }
    };

    // Callback to handle errors that can occur when initializing.
    final initErrorCallback = (dynamic error) {
      log.severe(error ?? 'Auth error was empty');
      _removeJsSDKEventListener(Event.ERROR);
      _removeJsSDKEventListener(Event.READY);
      // Same as above, defensive check.
      if (!_initializationResult.isCompleted) {
        _initializationResult.complete(false);
      } else {
        log.info(
            'JavaScript SDK failed response already handled. Ignoring subsequent response.');
      }
    };

    _registerAndStoreJSEventListener(Event.READY, readyCallback);
    _registerAndStoreJSEventListener(Event.ERROR_AUTH, initErrorCallback);

    return _initializationResult.future;
  }

  /// Registers the underlying JavaScript SDK event listeners, and emits events
  /// back to the core Flutter SDK using the plugin's host MethodChannel
  void _registerJsSDKStreamListeners() {
    final streamStartCallBack = (_) {
      _eventController.add({'event': EventType.SSE_START});
    };
    _registerAndStoreJSEventListener(Event.CONNECTED, streamStartCallBack);

    final streamDisconnectedCallBack = (_) {
      _eventController.add({'event': EventType.SSE_END});
    };
    _registerAndStoreJSEventListener(Event.DISCONNECTED, streamDisconnectedCallBack);

    final streamEvaluationChangeCallBack = (changeInfo) {
      FlagChange flagChange = changeInfo;
      Map<String, dynamic> evaluationResponse = {
        "flag": flagChange.flag,
        "value": flagChange.value
      };
      _eventController.add({
        'event': EventType.EVALUATION_CHANGE,
        'data':
            evaluationResponse // assuming flagInfo is some data you've retrieved
      });
    };
    _registerAndStoreJSEventListener(Event.CHANGED, streamEvaluationChangeCallBack);

    _eventController.stream.listen((event) {
      switch (event['event']) {
        case EventType.SSE_START:
          log.fine('Internal event received: SSE_START');
          _hostChannel.invokeMethod('start');
          break;
        case EventType.SSE_END:
          log.fine('Internal event received: SSE_END');
          _hostChannel.invokeMethod('end');
          break;
        case EventType.SSE_RESUME:
          log.fine('Internal event received: SSE_RESUME');
          break;
        case EventType.EVALUATION_POLLING:
          // TODO: The JavaScript SDK currently does not implement polling.
          break;
        case EventType.EVALUATION_CHANGE:
          log.fine('Internal event received EVALUATION_CHANGE');
          var evaluationResponse = event['data'];
          _hostChannel.invokeMethod('evaluation_change', evaluationResponse);
          break;
      }
    });
  }

  /// Helper function to register JavaScript SDK event listeners and store the
  /// function callback reference so they can be removed when requried.
  void _registerAndStoreJSEventListener(String event, Function callback) {
    JavaScriptSDKClient.on(event, allowInterop(callback));
    _registeredEventListeners[event]!.add(callback);
  }

  // TODO, `off` needs the original cb function reference. Fix.
  void _removeJsSDKEventListener(String event) {
    JavaScriptSDKClient.off(event, allowInterop((dynamic error) {
      log.severe('Error removing event listener: ' +
          (error ?? 'Auth error was empty'));
      return false;
    }));
  }

  /// Callback used for logging errors that have been emitted by the JS SDK
  void _errorCallback(String logString, dynamic error) {
    log.severe('$logString ' + (error ?? 'Error was empty'));
  }

  /// Helper function to turn a map into an object, which is the required
  /// type for interop with JavaScript objects
  Object _mapToJsObject(Map map) {
    final object = newObject();
    map.forEach((k, v) {
      if (v is Map) {
        setProperty(object, k, _mapToJsObject(v));
      } else {
        setProperty(object, k, v);
      }
    });
    return object;
  }
}
