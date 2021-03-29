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

/// Class representing a single evaluation response. It carries information about
/// changed evaluation's id and its value. The value type is dynamic and it is
/// SDK's end-user responsibility to know what type is used for given id
class EvaluationResponse {
  String evaluationId;
  dynamic evaluationValue;

  EvaluationResponse(this.evaluationId, this.evaluationValue);
}

/// Class used in [CfEventsListener] as possible event type that can be triggered by SDK.
enum EventType {
  /// Indicates that realtime evaluation update monitor is started. Has no payload.
  SSE_START,

  /// Indicates that realtime evaluation update monitor is ended. Has no payload.
  SSE_END,

  /// Evaluation list has been reloaded due to polling mechanism. The payload is
  /// list of loaded evaluation.
  /// See [EvaluationResponse]
  EVALUATION_POLLING,

  /// A single evaluation has been changed. The payload is an instance of [EvaluationResponse].
  EVALUATION_CHANGE
}

/// Type alias used in [CfClient.registerEventsListener] to receive events from SDK. It has two parameters:
/// - data: dynamic type since different events may carry different response
/// - eventType: instance of [EventType] class
/// For full list of possible event and response types, see [EventType] class
typedef void CfEventsListener(dynamic data, EventType eventType);

///
/// Main SDK client used for SDK initialization and flags evaluation. The initialization is done
/// with help of [CfConfigurationBuilder].
/// Example:
///```
/// final conf = CfConfigurationBuilder()
///     .setStreamEnabled(true)
///     .setPollingInterval(60) //time in seconds (minimum value is 60)
///     .build();
/// final target = CfTargetBuilder().setIdentifier(name).build();
///
/// final res = await CfClient.initialize(apiKey, conf, target);
///
///```
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

  /// Initializes the SDK client with provided API key, configuration and target. Returns information if
  /// initialization succeeded or not
  static Future<InitializationResult> initialize(String apiKey, CfConfiguration configuration, CfTarget target) async {
    _hostChannel.setMethodCallHandler(_hostChannelHandler);

    bool initialized = await _channel.invokeMethod('initialize', {
      'apiKey': apiKey,
      'configuration': configuration._toCodecValue(),
      'target': target._toCodecValue()
    });

    return new Future(() => InitializationResult(initialized));
  }

  /// Performs string evaluation for given evaluation id. If no such id is present, the default value will be returned.
  static Future<String> stringVariation(String evaluationId, String defaultValue) async {
    return _sendMessage('stringVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  /// Performs boolean evaluation for given evaluation id. If no such id is present, the default value will be returned.
  static Future<bool> boolVariation(String evaluationId, bool defaultValue) async {
    return _sendMessage('boolVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  /// Performs evaluation for given evaluation id with double value. If no such id is present, the default value will be returned.
  static Future<double> numberVariation(String evaluationId, double defaultValue) async {
    return _sendMessage('numberVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  static Future<Map<dynamic, dynamic>> jsonVariation(String evaluationId, Map<dynamic, dynamic> defaultValue) async {
    return _sendMessage('jsonVariation', new EvaluationRequest(evaluationId, defaultValue));
  }

  static Future<T> _sendMessage<T>(String messageType, EvaluationRequest evaluationRequest) async {
    return _channel.invokeMethod(messageType, evaluationRequest.toMap());
  }

  /// Register a listener for different types of events. Possible types are based on [EventType] class
  static Future<void> registerEventsListener(CfEventsListener listener) async {
    _listenerSet.add(listener);
    return _channel.invokeMethod('registerEventsListener');
  }

  /// Removes a previously-registered listener from internal collection of listeners. From this point, provided
  /// listener will not receive any events triggered by SDK
  static Future<void> unregisterEventsListener(CfEventsListener listener) async {
    _listenerSet.remove(listener);
  }

  /// Client's method to deregister and cleanup internal resources used by SDK
  static Future<void> destroy() async {
    _listenerSet.clear();
    return _channel.invokeMethod('destroy');
  }
}
