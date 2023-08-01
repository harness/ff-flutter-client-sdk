import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';

@JS('FFJavaScriptClientSDK')
@staticInterop
class FFJavaScriptClientSDK {
  external factory FFJavaScriptClientSDK();
}

extension FFJavaScriptClientSDKExtension on FFJavaScriptClientSDK {
  external dynamic initialize(String apiKey, dynamic target, dynamic options);
  external dynamic registerEvent(String eventType, Function callback);
}

final log = Logger('FFWebPluginLogger');

class FlutterPluginWeb {

  // The instance of the wrapper around the JS SDK
  static final harness = FFJavaScriptClientSDK();

  // This channel is used to send JavaScript SDK events to the Flutter
  // SDK Code.
  static const MethodChannel _hostChannel = const MethodChannel('cf_flutter_host');

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'ff_flutter_client_sdk',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = FlutterPluginWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the [MethodChannel] of this plugin.
  /// Note: Check the incoming method name to call your implementation accordingly.
  Future<dynamic> handleMethodCall(MethodCall call) async {
    FFJavaScriptClientSDK harness = FFJavaScriptClientSDK();
    switch (call.method) {
      case 'initialize':
        return harness.initialize(call.arguments["apiKey"], call.arguments["target"], call.arguments["options"]);
      case 'registerEvent':
        return harness.registerEvent(call.arguments["eventType"], allowInterop((dynamic event) {
          // Process JavaScript call here
        }));
    }
  }

  Future<dynamic> boolVariation(Map<String, dynamic> arguments) async {
    // TODO: Implement your web-specific logic here
  }

  Future<dynamic> stringVariation(Map<String, dynamic> arguments) async {
    // TODO: Implement your web-specific logic here
  }
}
