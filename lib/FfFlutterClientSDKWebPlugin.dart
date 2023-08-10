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
    Map<String, dynamic> target =
        Map<String, dynamic>.from(call.arguments['target']);
    Map<String, dynamic> options =
        Map<String, dynamic>.from(call.arguments['configuration']);
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
        initializationResult.complete(true);
      } else {
        log.info('JavaScript SDK success response already handled. Ignoring subsequent response.');
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
        log.info('JavaScript SDK failed response already handled. Ignoring subsequent response.');
      }
    }

    registerJsSDKEventListener(Event.READY, readyCallback);
    registerJsSDKEventListener(Event.ERROR_AUTH, initErrorCallback);

    return initializationResult.future;
  }

  void registerJsSDKEventListener(String event, Function callback) {
    JavaScriptSDKClient.on(event, allowInterop(callback));
  }

  void removeJsSDKEventListener(String event) {
    JavaScriptSDKClient.off(event, allowInterop((dynamic error) {
      log.severe('Error removing event listener: ' + (error ?? 'Auth error was empty'));
      return false;
    }));
  }

  // Callback used for logging errors that have been emitted by the JS SDK
  void errorCallback(String logString, dynamic error) {
    log.severe('$logString ' + (error ?? 'Auth error was empty'));
  }
}
