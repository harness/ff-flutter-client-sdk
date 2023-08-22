@JS()
library ff_web_plugin;

import 'dart:async';
import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'CfClient.dart';
import 'web_plugin_internal//FfJavascriptSDKInterop.dart';

@JS('window')
external dynamic get window;

// Type used to group callback functions used when registering
// stream events with the JavaScript SDK
class JsSDKStreamCallbackFunctions {
  final Function connectedFunction;
  final Function changedFunction;
  final Function disconnectedFunction;

  JsSDKStreamCallbackFunctions(
      this.connectedFunction, this.disconnectedFunction, this.changedFunction);
}

class FfFlutterClientSdkWebPlugin {
  final log = Logger('FfFlutterClientSdkWebPluginLogger');
  // The method calls that the core Flutter SDK can make
  static const _initializeMethodCall = 'initialize';
  static const _registerEventsListenerMethodCall = 'registerEventsListener';
  static const _unregisterEventsListenerMethodCall = 'unregisterEventsListener';
  static const _variationMethodCall = 'variation';

  // Used to emit JavaScript SDK events to the host MethodChannel
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  // The core Flutter SDK passes uuids over the method channel for each
  // listener that has been registered. This maps the UUID to the event and function callback
  // we pass to the JavaScript SDK, so they can be unregistered by users later.
  Map<String, JsSDKStreamCallbackFunctions> _uuidToEventListenerMap = {};

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
        final uuid = call.arguments['uuid'];
        _registerJsSDKStreamListeners(uuid);
        break;
      case _unregisterEventsListenerMethodCall:
        final uuid = call.arguments['uuid'];
        log.fine("test");
        _unregisterJsSDKStreamListeners(uuid);
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
    return await _waitForInitializationResult();
  }

  Future<bool> _waitForInitializationResult() async {
    final initializationResult = Completer<bool>();

    // Callback for the JavaScript SDK's READY event. It returns a list of
    // evaluations, but we don't need them in this plugin.
    final readyCallback = ([_]) {
      // While we shouldn't attempt to complete this completer more than once,
      // this is a defensive check and log if it is attempted.
      if (!initializationResult.isCompleted) {
        initializationResult.complete(true);
      } else {
        log.fine(
            'JavaScript SDK success response already handled. Ignoring subsequent response.');
      }
    };

    // Callback to handle errors that can occur when initializing.
    final initErrorCallback = (dynamic error) {
      // Same as above, defensive check.
      if (!initializationResult.isCompleted) {
        log.severe("FF SDK failed to initialize: " +
            (error?.toString() ?? 'Auth error was empty'));
        initializationResult.complete(false);
      } else {
        log.fine(
            'JavaScript SDK failed response already handled. Ignoring subsequent response.');
      }
    };

    // Listen for the JavaScript SDK READY / ERROR_AUTH events to be emitted
    JavaScriptSDKClient.on(Event.READY, allowInterop(readyCallback));
    JavaScriptSDKClient.on(Event.ERROR_AUTH, allowInterop(initErrorCallback));

    final result = await initializationResult.future;

    // After READY or ERROR_AUTH has been emitted and we have a result,
    // then unregister these listeners from the JavaScript SDK as we don't
    // need them anymore.
    _removeJsSDKEventListener(Event.READY, readyCallback);
    _removeJsSDKEventListener(Event.ERROR_AUTH, initErrorCallback);

    return result;
  }

  /// Registers the underlying JavaScript SDK event listeners, and emits events
  /// back to the core Flutter SDK using the plugin's host MethodChannel
  void _registerJsSDKStreamListeners2(uuid) {
    final streamStartCallBack = (_) {
      _eventController.add({'event': EventType.SSE_START});
    };

    final streamDisconnectedCallBack = (_) {
      _eventController.add({'event': EventType.SSE_END});
    };

    final streamEvaluationChangeCallBack = (changeInfo) {
      FlagChange flagChange = changeInfo;
      Map<String, dynamic> evaluationResponse = {
        "flag": flagChange.flag,
        "value": flagChange.value
      };
      _eventController.add(
          {'event': EventType.EVALUATION_CHANGE, 'data': evaluationResponse});
    };
    JavaScriptSDKClient.on(Event.CONNECTED, allowInterop(streamStartCallBack));
    JavaScriptSDKClient.on(
        Event.DISCONNECTED, allowInterop(streamDisconnectedCallBack));
    JavaScriptSDKClient.on(
        Event.CHANGED, allowInterop(streamEvaluationChangeCallBack));

    _uuidToEventListenerMap[uuid] = JsSDKStreamCallbackFunctions(
        streamStartCallBack,
        streamDisconnectedCallBack,
        streamEvaluationChangeCallBack);

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

  void _registerJsSDKStreamListeners(String uuid) {
    final callbacks = {
      Event.CONNECTED: (_) =>
          _eventController.add({'event': EventType.SSE_START}),
      Event.DISCONNECTED: (_) =>
          _eventController.add({'event': EventType.SSE_END}),
      Event.CHANGED: (changeInfo) {
        FlagChange flagChange = changeInfo;
        Map<String, dynamic> evaluationResponse = {
          "flag": flagChange.flag,
          "value": flagChange.value
        };
        _eventController.add(
            {'event': EventType.EVALUATION_CHANGE, 'data': evaluationResponse});
      }
    };

    for (var event in callbacks.keys) {
      var callback = callbacks[event];
      JavaScriptSDKClient.on(event, allowInterop(callback!));
    }

    _uuidToEventListenerMap[uuid] = JsSDKStreamCallbackFunctions(
        callbacks[Event.CONNECTED]!,
        callbacks[Event.DISCONNECTED]!,
        callbacks[Event.CHANGED]!);

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

  void _unregisterJsSDKStreamListeners(String uuid) {
    JsSDKStreamCallbackFunctions? registeredEvent =
        _uuidToEventListenerMap[uuid];
    if (registeredEvent != null) {
      print("register: gonna unregister func on plugin side");
      JavaScriptSDKClient.off(
          Event.CONNECTED, allowInterop(registeredEvent.connectedFunction));
      JavaScriptSDKClient.off(Event.DISCONNECTED,
          allowInterop(registeredEvent.disconnectedFunction));
      JavaScriptSDKClient.off(
          Event.CHANGED, allowInterop(registeredEvent.changedFunction));
    } else {
      log.warning("Attempted to unregister event listener, but the"
          "requested event listener was not found.");
    }
  }

  // TODO, `off` needs the original cb function reference. Fix.
  void _removeJsSDKEventListener(String event, Function callBack) {
    JavaScriptSDKClient.off(event, allowInterop(callBack));
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
