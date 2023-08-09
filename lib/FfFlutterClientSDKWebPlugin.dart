@JS()
library static_interop;

import 'dart:async';
import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';
import 'web_plugin_internal//FfJavascriptSDKInterop.dart' as webJs;

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

final log = Logger('FfFlutterClientSdkWebPluginLogger');

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
    // FFJavaScriptClientSDK harness = FFJavaScriptClientSDK();
    switch (call.method) {
      case 'initialize':
        // return harness.initialize(call.arguments["apiKey"], call.arguments["target"], call.arguments["options"]);
        //   case 'registerEvent':
        //     return harness.registerEvent(call.arguments["eventType"], allowInterop((dynamic event) {
        //       // Process JavaScript call here
        //     }));
        final response =
            webJs.initialize("2809ada1-73ae-4008-9c75-f0b9e7sedd797", {
          'name': 'Sample Name',
          'identifier': 12345,
          'isAnonymous': false,
          'attributes': {'key1': 'value1', 'key2': 'value2'}
        }, {});
        var propertyValue = getProperty(response, 'on');
        print(propertyValue);
        return true;
    }
  }

  Future<dynamic> boolVariation(Map<String, dynamic> arguments) async {
    // TODO: Implement your web-specific logic here
  }

  Future<dynamic> stringVariation(Map<String, dynamic> arguments) async {
    // TODO: Implement your web-specific logic here
  }
}
