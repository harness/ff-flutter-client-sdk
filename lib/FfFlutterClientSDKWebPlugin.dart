@JS()
library ff_web_plugin;

import 'dart:async';
import 'dart:convert';
import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'CfClient.dart';
import 'web_plugin_internal//FfJavascriptSDKInterop.dart';

@JS('window')
external dynamic get window;

enum Events {
  STREAMING_CONNECTED,
  STREAMING_EVALUATION,
  POLLING_EVALUATION,
  STREAMING_DISCONNECTED,
}

// Type used to group callback functions used when registering
// stream events with the JavaScript SDK
class JsSDKStreamCallbackFunctions {
  final Function connectedFunction;
  final Function disconnectedFunction;
  final Function streamingEvaluationFunction;
  final Function pollingEvaluationFunction;

  JsSDKStreamCallbackFunctions(
      {required this.connectedFunction,
      required this.disconnectedFunction,
      required this.streamingEvaluationFunction,
      required this.pollingEvaluationFunction});
}

class FfFlutterClientSdkWebPlugin {
  final log = Logger('FfFlutterClientSdkWebPluginLogger');
  // The method calls that the core Flutter SDK can make
  static const _initializeMethodCall = 'initialize';
  static const _registerEventsListenerMethodCall = 'registerEventsListener';
  static const _boolVariationMethodCall = 'boolVariation';
  static const _stringVariationMethodCall = 'stringVariation';
  static const _numberVariationMethodCall = 'numberVariation';
  static const _jsonVariationMethodCall = 'jsonVariation';
  static const _unregisterEventsListenerMethodCall = 'unregisterEventsListener';
  static const _destroyMethodCall = 'destroy';

  // Used so we can subscribe to correct events in the JavaScript SDK
  static late bool streamingEnabled;

  // The JS SDK emits `CONNECTED` for the first time it connects, and even for stream reconnects after a failure,
  // so we need to keep track of if the stream is currently disconnected so that
  // we can take action and emit the SSE_RESUME event.
  static bool streamingDisconnected = false;

  // Used to emit JavaScript SDK events to the host MethodChannel
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  // Keep track of the JavaScript SDK event subscription so we can close it
  // if users close the SDK.
  StreamSubscription? _eventSubscription;

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
      case _destroyMethodCall:
        destroy();
        break;
      default:
        if (call.method == _boolVariationMethodCall ||
            call.method == _stringVariationMethodCall ||
            call.method == _numberVariationMethodCall ||
            call.method == _jsonVariationMethodCall) {
          return await _invokeVariation(call);
        }
        break;
    }
  }

  Future<bool> _invokeInitialize(MethodCall call) async {
    final String apiKey = call.arguments['apiKey'];
    final Object target = _mapToJsObject(call.arguments['target']);
    final Map flutterOptions = call.arguments['configuration'];

    final bool streamingOption = flutterOptions['streamEnabled'];

    // Keep track of the streaming option the user has chosen, so we can
    // register the right listener when the user sets up a listener
    streamingEnabled = streamingOption;

    final javascriptSdkOptions = Options(
        baseUrl: flutterOptions['configUrl'],
        eventUrl: flutterOptions['eventUrl'],
        pollingInterval: flutterOptions['pollingInterval'],
        // Enable polling by default for the JS SDK, so we can fallback to polling
        // of stream fails.
        pollingEnabled: true,
        streamEnabled: streamingOption,
        debug: flutterOptions['debugEnabled']);

    final response =
        JavaScriptSDK.initialize(apiKey, target, javascriptSdkOptions);

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
    JavaScriptSDKClient.off(Event.READY, allowInterop(readyCallback));
    JavaScriptSDKClient.off(Event.ERROR_AUTH, allowInterop(initErrorCallback));

    return result;
  }

  /// Registers the underlying JavaScript SDK event listeners, and emits events
  /// back to the core Flutter SDK using the plugin's host MethodChannel
  void _registerJsSDKStreamListeners(String uuid) {
    final Map<String, Function> callbacks = {};

    final pollingEvaluationCallBack = (polledFlags) {
      dynamic flags = polledFlags;
      List<dynamic> evaluationResponses = flags.map((flagChange) {
        return {
          "flag": flagChange.flag,
          "kind": flagChange.kind,
          "value": flagChange.value
        };
      }).toList();
      _eventController.add(
          {'event': Events.POLLING_EVALUATION, 'data': evaluationResponses});
    };

    final streamingConnectedCallback = (_) {
      _eventController.add({'event': Events.STREAMING_CONNECTED});
    };

    final streamingDisconnectedCallback = (_) {
      _eventController.add({'event': Events.STREAMING_DISCONNECTED});
    };

    final streamingCallBack = (changeInfo) {
      FlagChange flagChange = changeInfo;
      Map<String, dynamic> evaluationResponse = {
        "flag": flagChange.flag,
        "kind": flagChange.kind,
        "value": flagChange.value
      };
      _eventController.add(
          {'event': Events.STREAMING_EVALUATION, 'data': evaluationResponse});
    };

    // Only register streaming callbacks if streaming is enabled
    if (streamingEnabled) {
      callbacks[Event.CONNECTED] = streamingConnectedCallback;
      callbacks[Event.DISCONNECTED] = streamingDisconnectedCallback;
      callbacks[Event.CHANGED] = streamingCallBack;
    }

    // Register polling callback by default, which is enabled even if
    // streaming is enabled as it is used as a fallback
    callbacks[Event.FLAGS_LOADED] = pollingEvaluationCallBack;

    for (final event in callbacks.keys) {
      final callback = callbacks[event];
      JavaScriptSDKClient.on(event, allowInterop(callback!));
    }

    _uuidToEventListenerMap[uuid] = JsSDKStreamCallbackFunctions(
        connectedFunction: callbacks[Event.CONNECTED]!,
        disconnectedFunction: callbacks[Event.DISCONNECTED]!,
        streamingEvaluationFunction: callbacks[Event.CHANGED]!,
        pollingEvaluationFunction: callbacks[Event.FLAGS_LOADED]!);

    _eventSubscription = _eventController.stream.listen((event) {
      switch (event['event']) {
        case Events.STREAMING_CONNECTED:
          if (streamingEnabled && streamingDisconnected) {
            // Refresh the cache so listeners to SSE_RESUME can be assured they
            // get the most up to date values
            streamingDisconnected = false;
            JavaScriptSDKClient.refreshEvaluations();
            _hostChannel.invokeMethod('resume');
            return;
          }
          _hostChannel.invokeMethod('start');
          break;
        case Events.STREAMING_DISCONNECTED:
          streamingDisconnected = true;
          return;
        case Events.POLLING_EVALUATION:
          if (streamingEnabled && streamingDisconnected) {
            return;
          }
          // Only send polling evaluations if streaming is disconnected because
          // the `FLAGS_LOADED` event from the JS SDK is triggered when the
          // SDK initializes
          log.fine('Internal event received EVALUATION_POLLING');
          final pollingEvaluations = event['data'];
          _hostChannel.invokeMethod(
              'evaluation_polling', {'evaluationData': pollingEvaluations});
          break;
        case Events.STREAMING_EVALUATION:
          log.fine('Internal event received EVALUATION_CHANGE');
          final evaluationResponse = event['data'];
          _hostChannel.invokeMethod('evaluation_change', evaluationResponse);
          break;
      }
    });
  }

  void _unregisterJsSDKStreamListeners(String uuid) {
    JsSDKStreamCallbackFunctions? callBackFunctions =
        _uuidToEventListenerMap[uuid];
    if (callBackFunctions != null) {
      if (streamingEnabled) {
        JavaScriptSDKClient.off(
            Event.CONNECTED, allowInterop(callBackFunctions.connectedFunction));
        JavaScriptSDKClient.off(Event.DISCONNECTED,
            allowInterop(callBackFunctions.disconnectedFunction));
        JavaScriptSDKClient.off(Event.CHANGED,
            allowInterop(callBackFunctions.streamingEvaluationFunction));
      }
      JavaScriptSDKClient.off(Event.FLAGS_LOADED,
          allowInterop(callBackFunctions.pollingEvaluationFunction));

      _uuidToEventListenerMap.remove(uuid);
    } else {
      log.warning("Attempted to unregister event listener, but the"
          "requested event listener was not found.");
    }
  }

  Future<dynamic> _invokeVariation(MethodCall call) async {
    final flagIdentifier = call.arguments['flag'];
    final defaultValue = call.arguments['defaultValue'];
    final VariationResult result =
        await JavaScriptSDKClient.variation(flagIdentifier, defaultValue, true);
    if (result.isDefaultValue) {
      log.warning(
          "Flag '${flagIdentifier}' not found when calling ${call.method}. Default value returned.");
    }
    // The JavaScript SDK returns a json string, so we need to encode it as the
    // type expected by the core Flutter SDK
    if (call.method == _jsonVariationMethodCall && !result.isDefaultValue) {
      return jsonDecode(result.value);
    }
    return result.value;
  }

  void destroy() {
    // Cleanup JavaScript SDK resources
    JavaScriptSDKClient.close();

    // Cancel any JS SDK subscriptions that may have been registered
    _eventSubscription?.cancel();
    _uuidToEventListenerMap.clear();
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
