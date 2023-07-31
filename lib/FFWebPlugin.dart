@JS()
library callable_function;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('jsOnEvent')
external set _jsOnEvent(void Function(dynamic event) f);

@JS()
external dynamic jsInvokeMethod(String method, String? params);

class FlutterPluginWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'ff_flutter_client_sdk',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = FlutterPluginWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);

    //Sets the call from JavaScript handler
    _jsOnEvent = allowInterop((dynamic event) {
      //Process JavaScript call here
    });
  }

  /// Handles method calls over the [MethodChannel] of this plugin.
  /// Note: Check the incoming method name to call your implementation accordingly.
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
        return initialize(call.arguments);
      case 'boolVariation':
        return boolVariation(call.arguments);
    }
  }

  Future<dynamic> initialize(Map<String, dynamic> arguments) async {
    // TODO: Implement your web-specific logic here
  }

  Future<dynamic> boolVariation(Map<String, dynamic> arguments) async {
    // TODO: Implement your web-specific logic here
  }

  Future<dynamic> stringVariation(Map<String, dynamic> arguments) async {
    // TODO: Implement your web-specific logic here
  }

  Future<dynamic> sendMethodMessage(
      String method, String? arguments) async {
    final dynamic response =
    await promiseToFuture(jsInvokeMethod(method, arguments));
    //...
  }
}