@JS()
library static_interop;

import 'dart:async';
import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'web_plugin_internal//FfJavascriptSDKInterop.dart' as ffJsSDKInterop;

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
        return invokeInitialize(call);
    }
  }

  bool invokeInitialize(MethodCall call) {
    final String apiKey = call.arguments['apiKey'];
    Map<String, dynamic> target =
        Map<String, dynamic>.from(call.arguments['target']);
    Map<String, dynamic> options =
        Map<String, dynamic>.from(call.arguments['configuration']);
    try {
      final response = ffJsSDKInterop.initialize(apiKey, target, options);
      // The JavaScript SDK returns the client instance, whether or not
      // the initialization was successful. We set a reference to it on
      // the global window, and then we can listen if initialization was
      // successful or not.
      setProperty(
          window, ffJsSDKInterop.JavaScriptSDKClient.windowReference, response);

      setupEventListener(ffJsSDKInterop.Event.ERROR_AUTH);
      // var propertyValue = getProperty(response, ffJsSDK.ClientFunctions.on);
      // print(propertyValue);
    } catch (error) {}
    return true;
  }

  void setupEventListener(String event) {
    ffJsSDKInterop.on(event, allowInterop(handleError));
  }

  void handleError(dynamic error) {
    print("Received JS event ERROR with data $error");
    // Handle the event in Dart, similar to how you'd handle it in JS
  }

  // Future<dynamic> boolVariation(Map<String, dynamic> arguments) async {
  //   // TODO: Implement your web-specific logic here
  // }
  //
  // Future<dynamic> stringVariation(Map<String, dynamic> arguments) async {
  //   // TODO: Implement your web-specific logic here
  // }
}
