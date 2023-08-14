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
  static const _initializeMethodCall = 'initialize';
  static const _variationMethodCall = 'variation';

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  // Keep track of unique events we are listening to from the JavaScript SDK
  // Registering a listener doesn't return a reference we can keep track of,
  // instead we just update this set with the event type.
  // This prevents the accidental registering of more than one event type.
  static Set<String> _registeredListeners = {};

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
    final _initializationResult = Completer<bool>();

    // Callback for the JavaScript SDK's READY event. It returns a list of
    // evaluations, but we don't need them in this plugin.
    final readyCallback = ([_]) {
      // While we shouldn't attempt to complete this completer more than once,
      // this is a defensive check and log if it is attempted.
      if (!_initializationResult.isCompleted) {
        // Start listening for the required events emitted by the JavaScript SDK
        // TODO I think this should be registered onDemand, as `registerEventListener` is invoked by Flutter core sdk
        _registerJsSDKStreamListeners();
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

    _registerJsSDKEventListener(Event.READY, readyCallback);
    _registerJsSDKEventListener(Event.ERROR_AUTH, initErrorCallback);

    return _initializationResult.future;
  }

  void _registerJsSDKEventListener(String event, Function callback) {
    if (_registeredListeners.contains(event)) {
      log.info(
          'Listener for $event already registered. Skipping subsequent registration.');
      return;
    }
    JavaScriptSDKClient.on(event, allowInterop(callback));
    _registeredListeners.add(event);
  }

  /// Registers the underlying JavaScript SDK event listeners, and emits events
  /// back to the core Flutter SDK using the plugin's host MethodChannel
  void _registerJsSDKStreamListeners() {
    JavaScriptSDKClient.on(Event.CONNECTED, allowInterop((_) {
      _eventController.add({'event': EventType.SSE_START});
    }));

    JavaScriptSDKClient.on(Event.DISCONNECTED, allowInterop((_) {
      _eventController.add({'event': EventType.SSE_END});
    }));

    JavaScriptSDKClient.on(Event.CHANGED, allowInterop((changeInfo) {
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
    }));

    _eventController.stream.listen((event) {
      switch (event['event']) {
        case EventType.SSE_START:
          _hostChannel.invokeMethod('start');
          log.fine('Internal event received SSE_START');

          break;
        case EventType.SSE_END:
          _hostChannel.invokeMethod('end');
          log.fine('Internal event received SSE_START');

          break;
        case EventType.SSE_RESUME:
          log.fine('Internal event received SSE_RESUME');

          break;
        case EventType.EVALUATION_POLLING:
          // TODO: Handle this case.
          break;
        case EventType.EVALUATION_CHANGE:
          log.fine('Internal event received EVALUATION_CHANGE');
          var evaluationResponse = event['data'];
          _hostChannel.invokeMethod('evaluation_change', evaluationResponse);
          break;
      }
    });
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
    var object = newObject();
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
