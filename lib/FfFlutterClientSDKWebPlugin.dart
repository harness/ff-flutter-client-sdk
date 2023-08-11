@JS()
library ff_web_plugin;

import 'dart:async';
import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'web_plugin_internal//FfJavascriptSDKInterop.dart';

@JS('window')
external dynamic get window;

final log = Logger('FfFlutterClientSdkWebPluginLogger');

class FfFlutterClientSdkWebPlugin {
  static const initializeMethodCall = 'initialize';
  static const variationMethodCall = 'variation';

  // Keep track of unique events we are listening to from the JavaScript SDK
  // Registering a listener doesn't return a reference we can keep track of,
  // instead we just update this set with the event type.
  // This prevents the accidental registering of more than one event type.
  static Set<String> registeredListeners = {};

  // This channel is used to send JavaScript SDK events to the Flutter
  // SDK Code.
  static const MethodChannel _hostChannel =
      const MethodChannel('cf_flutter_host');

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'ff_flutter_client_sdk',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = FfFlutterClientSdkWebPlugin();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the [MethodChannel] for this plugin
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case initializeMethodCall:
        return await invokeInitialize(call);
    }
  }

  Future<bool> invokeInitialize(MethodCall call) async {
    final String apiKey = call.arguments['apiKey'];
    final Object target = mapToJsObject(call.arguments['target']);
    final Object options = mapToJsObject(call.arguments['configuration']);
    final response = JavaScriptSDK.initialize(apiKey, target, options);

    // The JavaScript SDK returns the client instance, whether or not
    // the initialization was successful. We set a reference to it on
    // the global window, and then we can listen if initialization was
    // successful or not.
    setProperty(window, JavaScriptSDKClient.windowReference, response);

    // Used to return the result of initialize after the JavaScript SDK
    // emits either a READY or ERROR event.
    final initializationResult = Completer<bool>();

    // Callback for the JavaScript SDK's READY event
    void readyCallback([_]) {
      // While we shouldn't attempt to complete this completer more than once,
      // this is a defensive check and log if it is attempted.
      if (!initializationResult.isCompleted) {
        // Start listening for the required events emitted by the JavaScript SDK
        registerJsSDKEventListener(Event.CHANGED, eventChangedCallBack);
        registerJsSDKEventListener(Event.CONNECTED, eventChangedCallBack);
        registerJsSDKEventListener(Event.DISCONNECTED, eventChangedCallBack);

        initializationResult.complete(true);
      } else {
        log.info(
            'JavaScript SDK success response already handled. Ignoring subsequent response.');
      }
    }

    // Callback to handle errors that can occur when initializing.
    void initErrorCallback(dynamic error) {
      log.severe(error ?? 'Auth error was empty');
      removeJsSDKEventListener(Event.ERROR);
      removeJsSDKEventListener(Event.READY);
      // Same as above, defensive check.
      if (!initializationResult.isCompleted) {
        initializationResult.complete(false);
      } else {
        log.info(
            'JavaScript SDK failed response already handled. Ignoring subsequent response.');
      }
    }

    registerJsSDKEventListener(Event.READY, readyCallback);
    registerJsSDKEventListener(Event.ERROR_AUTH, initErrorCallback);

    return initializationResult.future;
  }

  /// Callback to handle the JavaScript SDK's [Event.CHANGED] event
  void eventChangedCallBack() {

  }

  void registerJsSDKEventListener(String event, Function callback) {
    if (registeredListeners.contains(event)) {
      log.info(
          'Listener for $event already registered. Skipping subsequent registration.');
      return;
    }
    JavaScriptSDKClient.on(event, allowInterop(callback));
    registeredListeners.add(event);
  }

  // TODO - "off" currently not working correctly in the JS SDK. See: https://harness.atlassian.net/browse/FFM-8996
  void removeJsSDKEventListener(String event) {
    JavaScriptSDKClient.off(event, allowInterop((dynamic error) {
      log.severe('Error removing event listener: ' +
          (error ?? 'Auth error was empty'));
      return false;
    }));
  }

  void registerHostEventListener() {}

  // Callback used for logging errors that have been emitted by the JS SDK
  void errorCallback(String logString, dynamic error) {
    log.severe('$logString ' + (error ?? 'Error was empty'));
  }

  // Helper function to turn a map into an object, which is the required
  // type for interop with JavaScript objects
  Object mapToJsObject(Map map) {
    var object = newObject();
    map.forEach((k, v) {
      if (v is Map) {
        setProperty(object, k, mapToJsObject(v));
      } else {
        setProperty(object, k, v);
      }
    });
    return object;
  }
}
