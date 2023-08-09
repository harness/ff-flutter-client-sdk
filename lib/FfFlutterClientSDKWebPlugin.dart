@JS()
library static_interop;

import 'dart:async';
import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'web_plugin_internal//FfJavascriptSDKInterop.dart' as ffJsSDK;

// @JS('FFJavaScriptClientSDK')
// @staticInterop
// class FFJavaScriptClientSDK {
//   external factory FFJavaScriptClientSDK();
// }
//
// extension FFJavaScriptClientSDKExtension on FFJavaScriptClientSDK {
//   external dynamic initialize(String apiKey, dynamic target, dynamic options);
//   external dynamic registerEvent(String eventType, Function callback);
// }

@JS('window')
external dynamic get window;

final log = Logger('FfFlutterClientSdkWebPluginLogger');

final clientWindowReference = "cfclient";

class FfFlutterClientSdkWebPlugin {
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
      case 'initialize':
        final String apiKey = call.arguments['apiKey'];
        Map<String, dynamic> target =
            Map<String, dynamic>.from(call.arguments['target']);
        Map<String, dynamic> options =
            Map<String, dynamic>.from(call.arguments['configuration']);
        try {
          final response = ffJsSDK.initialize(apiKey, target, options);
          setProperty(window, clientWindowReference, response);
          var propertyValue = getProperty(response, 'on');
          print(propertyValue);
        } catch (error) {}
        return true;
    }
  }

  // Future<dynamic> boolVariation(Map<String, dynamic> arguments) async {
  //   // TODO: Implement your web-specific logic here
  // }
  //
  // Future<dynamic> stringVariation(Map<String, dynamic> arguments) async {
  //   // TODO: Implement your web-specific logic here
  // }
}
