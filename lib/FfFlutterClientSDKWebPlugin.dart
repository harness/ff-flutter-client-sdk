@JS()
library static_interop;

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

  // The instance of the wrapper around the JS SDK
  // static final harness = FFJavaScriptClientSDK();

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

  /// Handles method calls over the [MethodChannel] of this plugin.
  /// Note: Check the incoming method name to call your implementation accordingly.
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

    // Used to return a the result of initialized when the JavaScript SDK
    // emits either a READY or ERROR event.
    final completer = Completer<bool>();

    void errorCallback(dynamic error) {
      log.severe(error ?? 'Auth error was empty');
      removeJsSDKEventListener(Event.ERROR);
      removeJsSDKEventListener(Event.READY);
      // While we shouldn't attempt to complete this completer more than once,
      // this is a defensive check and log if it is attempted.
      if (!completer.isCompleted) {
        completer.complete(false);
      } else {
        log.info('SDK response already handled. Ignoring subsequent response.');
      }
    }

    void readyCallback([_]) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }

    registerJsSDKEventListener(Event.ERROR_AUTH, errorCallback);
    registerJsSDKEventListener(Event.READY, readyCallback);

    return completer.future;
  }

  void registerJsSDKEventListener(String event, Function callback) {
    JavaScriptSDKClient.on(event, allowInterop(callback));
  }

  void removeJsSDKEventListener(String event) {
    JavaScriptSDKClient.off(event, allowInterop(authErrorCallback));
  }

  bool authErrorCallback(dynamic error) {
    log.severe(error ?? 'Auth error was empty');
    return false;
  }

  // Future<dynamic> boolVariation(Map<String, dynamic> arguments) async {
  //   // TODO: Implement your web-specific logic here
  // }
  //
  // Future<dynamic> stringVariation(Map<String, dynamic> arguments) async {
  //   // TODO: Implement your web-specific logic here
  // }
}
