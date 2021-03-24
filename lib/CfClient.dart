library ff_flutter_client_sdk;

import 'dart:async';
import 'dart:collection';
import 'package:flutter/services.dart';
part 'CfTarget.dart';
part 'CfConfiguration.dart';

class InitializationResult {
  InitializationResult(bool value) {
    this.success = value;
  }

  bool success;
}

class EvaluationRequest {
  String evaluationId;
  dynamic defaultValue;

  EvaluationRequest(this.evaluationId, this.defaultValue);

  Map<String, dynamic> toMap() {
    return {
      "evaluationId" : evaluationId,
      'defaultValue': defaultValue
    };
  }
}

class EvaluationResponse {
  String evaluationId;
  dynamic evaluationValue;

  EvaluationResponse(this.evaluationId, this.evaluationValue);
}

enum EventType {
  SSE_START,
  SSE_END,
  EVALUATION_POLLING,
  EVALUATION_CHANGE
}

typedef void CfEventsListener(dynamic data, EventType eventType);

class CfClient {
  static const MethodChannel _channel = const MethodChannel('ff_flutter_client_sdk');
  static const MethodChannel _hostChannel = const MethodChannel('cf_flutter_host');

  static Set<CfEventsListener> _listenerSet = new HashSet();

  static Future<void> _hostChannelHandler(MethodCall methodCall) async {
    if (methodCall.method == "start") {
      _listenerSet.forEach((element) {
        element(null, EventType.SSE_START);
      });
    } else if (methodCall.method == "end") {
      _listenerSet.forEach((element) {
        element(null, EventType.SSE_END);
      });
    } else if (methodCall.method == "evaluation_change") {
      String id = methodCall.arguments["evaluationId"];
      dynamic value = methodCall.arguments["evaluationValue"];

      EvaluationResponse response = EvaluationResponse(id, value);

      _listenerSet.forEach((element) {
        element(response, EventType.EVALUATION_CHANGE);
      });
    } else if (methodCall.method == "evaluation_polling") {

      List list = methodCall.arguments["evaluationData"] as List;
      List<EvaluationResponse>  resultList = [];

      list.forEach((element) {
        String id = element["evaluationId"];
        dynamic value = element["evaluationValue"];

        resultList.add(EvaluationResponse(id, value));
      });


      _listenerSet.forEach((element) {
        element(resultList, EventType.EVALUATION_POLLING);
      });
    }
  }

  static Future<InitializationResult> initialize(String apiKey, CfConfiguration configuration, CfTarget target) async {
    _hostChannel.setMethodCallHandler(_hostChannelHandler);

    bool initialized = await _channel.invokeMethod('initialize', {
      'apiKey': apiKey,
      'configuration': configuration._toCodecValue(),
      'target': target._toCodecValue()
    });

    return new Future(() => InitializationResult(initialized));
  }

  static Future<String> stringVariation(String evaluationId, String defaultValue) async {
    return _sendMessage('stringVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  static Future<bool> boolVariation(String evaluationId, bool defaultValue) async {
    return _sendMessage('boolVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  static Future<double> numberVariation(String evaluationId, double defaultValue) async {
    return _sendMessage('numberVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  static Future<Map<dynamic, dynamic>> jsonVariation(String evaluationId, Map<dynamic, dynamic> defaultValue) async {
    return _sendMessage('jsonVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  static Future<T> _sendMessage<T>(String messageType, EvaluationRequest evaluationRequest) async {
    return _channel.invokeMethod(messageType, evaluationRequest.toMap());
  }

  static Future<void> registerEventsListener(CfEventsListener listener) async {
    _listenerSet.add(listener);
    return _channel.invokeMethod('registerEventsListener');
  }
  
  static Future<void> unregisterEventsListener(CfEventsListener listener) async {
    _listenerSet.remove(listener);
  }

  static Future<void> destroy() async {
    _listenerSet.clear();
    return _channel.invokeMethod('destroy');
  }
}
