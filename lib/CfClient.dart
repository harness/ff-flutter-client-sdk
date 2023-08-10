library ff_flutter_client_sdk;

import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js;


part 'CfTarget.dart';

part 'CfConfiguration.dart';

final log = Logger('CFClientLogger');


class InitializationResult {
  InitializationResult(bool value) {
    this.success = value;
  }

  bool success = false;
}

class EvaluationRequest {
  String flag;
  dynamic defaultValue;

  EvaluationRequest(this.flag, this.defaultValue);

  Map<String, dynamic> toMap() {
    return {"flag": flag, 'defaultValue': defaultValue};
  }
}

/// Class representing a single evaluation response. It carries information about
/// changed evaluation's flag and its value. The value type is dynamic and it is
/// SDK's end-user responsibility to know what type is used for given id
class EvaluationResponse {
  String flag;
  dynamic value;

  EvaluationResponse(this.flag, this.value);
}

/// Class used in [CfEventsListener] as possible event type that can be triggered by SDK.
enum EventType {
  /// Indicates that realtime evaluation update monitor is started. Has no payload.
  SSE_START,

  /// Indicates that realtime evaluation update monitor has restarted after recovering from network failure. Has no payload.
  SSE_RESUME,

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

  static CfClient? _instance;

  MethodChannel _channel =
      const MethodChannel('ff_flutter_client_sdk');
  MethodChannel _hostChannel =
      const MethodChannel('cf_flutter_host');

  Set<CfEventsListener> _listenerSet = new HashSet();

  Future<void> _hostChannelHandler(MethodCall methodCall) async {
    if (methodCall.method == "start") {
      _listenerSet.forEach((element) {
        element(null, EventType.SSE_START);
      });
    } else if (methodCall.method == "end") {
      _listenerSet.forEach((element) {
        element(null, EventType.SSE_END);
      });
    } else if (methodCall.method == "resume") {
      _listenerSet.forEach((element) {
        element(null, EventType.SSE_RESUME);
      });
    }
    else if (methodCall.method == "evaluation_change") {
      String flag = methodCall.arguments["flag"];
      dynamic value = methodCall.arguments["value"];

      EvaluationResponse response = EvaluationResponse(flag, value);

      _listenerSet.forEach((element) {
        element(response, EventType.EVALUATION_CHANGE);
      });
    } else if (methodCall.method == "evaluation_polling") {
      List list = methodCall.arguments["evaluationData"] as List;
      List<EvaluationResponse> resultList = [];

      list.forEach((element) {
        String flag = element["flag"];
        dynamic value = element["value"];

        resultList.add(EvaluationResponse(flag, value));
      });

      _listenerSet.forEach((element) {
        element(resultList, EventType.EVALUATION_POLLING);
      });
    }
  }

  static CfClient getInstance() {

    if (_instance == null) {

      _instance = CfClient();
    }
    return _instance!;
  }

  /// Initializes the SDK client with provided API key, configuration and target. Returns information if
  /// initialization succeeded or not
  Future<InitializationResult> initialize(String apiKey,
      CfConfiguration configuration, CfTarget target) async {
    Logger.root.level = Level.SEVERE; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
    _hostChannel.setMethodCallHandler(_hostChannelHandler);
    bool initialized = false;
    try {
    initialized = await _channel.invokeMethod('initialize', {
      'apiKey': apiKey,
      'configuration': configuration._toCodecValue(),
      'target': target._toCodecValue()
    }); } on PlatformException catch(e) {
      // For now just log the error. In the future, we should add retry and backoff logic.
      log.severe(e.message ?? 'Error message was empty' + (e.details ?? 'Error details was empty').toString());
      return new Future(() => InitializationResult(false));
    }
    return new Future(() => InitializationResult(initialized));
  }

  /// Performs string evaluation for given evaluation id. If no such id is present, the default value will be returned.
  Future<String> stringVariation(String id, String defaultValue) async {
      return _sendMessage('stringVariation', new EvaluationRequest(id, defaultValue));
  }

  /// Performs boolean evaluation for given evaluation id. If no such id is present, the default value will be returned.
  Future<bool> boolVariation(String id, bool defaultValue) async {
    return _sendMessage(
        'boolVariation', new EvaluationRequest(id, defaultValue));
  }

  /// Performs evaluation for given evaluation id with double value. If no such id is present, the default value will be returned.
  Future<double> numberVariation(String id, double defaultValue) async {
    return _sendMessage(
        'numberVariation', new EvaluationRequest(id, defaultValue));
  }

  Future<Map<dynamic, dynamic>> jsonVariation(
      String flag, Map<dynamic, dynamic> defaultValue) async {
    return _sendMessage(
        'jsonVariation', new EvaluationRequest(flag, defaultValue));
  }

  Future<T> _sendMessage<T>(
      String messageType, EvaluationRequest evaluationRequest) async {
    return _channel.invokeMethod(messageType, evaluationRequest.toMap())
        .then((result) => result as T);
  }

  /// Register a listener for different types of events. Possible types are based on [EventType] class
  Future<void> registerEventsListener(CfEventsListener listener) async {
    _listenerSet.add(listener);
    return _channel.invokeMethod('registerEventsListener');
  }

  /// Removes a previously-registered listener from internal collection of listeners. From this point, provided
  /// listener will not receive any events triggered by SDK
  Future<void> unregisterEventsListener(
      CfEventsListener listener) async {
    _listenerSet.remove(listener);
  }

  /// Client's method to deregister and cleanup internal resources used by SDK
  Future<void> destroy() async {
    _listenerSet.clear();
    return _channel.invokeMethod('destroy');
  }
}
