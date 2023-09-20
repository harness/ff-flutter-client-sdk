library ff_flutter_client_sdk;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

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

  // A map to hold UUID against the CfEventsListener references
  final Map<CfEventsListener, String> _listenerUuidMap = {};

  final _uuid = Uuid();

  MethodChannel _channel = const MethodChannel('ff_flutter_client_sdk');
  MethodChannel _hostChannel = const MethodChannel('cf_flutter_host');

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
    } else if (methodCall.method == "evaluation_change") {
      final String flag = methodCall.arguments["flag"];

      final dynamic value = methodCall.arguments["value"];

      // TODO - the iOS SDK doesn't emit this so it will need a very
      //  minor SDK update there. For now, iOS will use the string SSE
      // values.
      final String? kind = methodCall.arguments["kind"];
      final dynamic parsedValue =
          kind != null ? convertValueByKind(kind, value) : value;
      final response = EvaluationResponse(flag, parsedValue);

      _listenerSet.forEach((element) {
        element(response, EventType.EVALUATION_CHANGE);
      });
    } else if (methodCall.method == "evaluation_polling") {
      List list = methodCall.arguments["evaluationData"];
      List<EvaluationResponse> resultList = [];

      list.forEach((element) {
        final dynamic value = element["value"];
        final String? kind = element["kind"];
        final dynamic parsedValue =
        kind != null ? convertValueByKind(kind, value) : value;
        String flag = element["flag"];

        resultList.add(EvaluationResponse(flag, parsedValue));
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
  Future<InitializationResult> initialize(
      String apiKey, CfConfiguration configuration, CfTarget target) async {
    Logger.root.level = configuration.logLevel; // defaults to Level.INFO
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
      });
    } on PlatformException catch (e) {
      // For now just log the error. In the future, we should add retry and backoff logic.
      log.severe(e.message ??
          'Error message was empty' +
              (e.details ?? 'Error details was empty').toString());
      return new Future(() => InitializationResult(false));
    }
    return new Future(() => InitializationResult(initialized));
  }

  /// Performs string evaluation for given evaluation id. If no such id is present, the default value will be returned.
  Future<String> stringVariation(String id, String defaultValue) async {
    return _sendMessage(
        'stringVariation', new EvaluationRequest(id, defaultValue));
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
    return _channel
        .invokeMethod(messageType, evaluationRequest.toMap())
        .then((result) => result as T);
  }

  /// Register a listener for different types of events. Possible types are based on [EventType] class
  Future<void> registerEventsListener(CfEventsListener listener) async {
    _listenerSet.add(listener);

    if (!kIsWeb) return _channel.invokeMethod('registerEventsListener');

    // For the web platform, pass the listener reference so that it can be removed
    // later, so that the JavaScript SDK can stop emitting events when not needed.
    // TODO needs implemented for Android/iOS, but for now, those platforms have destroy.
    if (!_listenerUuidMap.containsKey(listener)) {
      final uuid = _uuid.v4();
      _listenerUuidMap[listener] = uuid;
      return _channel.invokeMethod('registerEventsListener', {'uuid': uuid});
    }
  }

  /// Removes a previously-registered listener from internal collection of listeners. From this point, provided
  /// listener will not receive any events triggered by SDK
  Future<void> unregisterEventsListener(CfEventsListener listener) async {
    _listenerSet.remove(listener);
    // For the web platform, ensure the JavaScript SDK stops emitting
    // events when it is not needed. TODO, for iOS and Android, needs an
    // unregisterEventsListener implemented. For now, those platforms have
    // destroy.
    if (kIsWeb && _listenerUuidMap[listener] != null) {
      return _channel.invokeMethod(
          'unregisterEventsListener', {'uuid': _listenerUuidMap[listener]});
    }
  }

  // At present, the Android and iOS SDKs (not JavaScript) SSE events return evaluation values
  // as strings. This is a function to standardise them into the correct type,
  // so the SSE evaluations are the same underlying type as the variation
  // evaluations.
  // We return as dynamic in order to keep backwards compatability, but
  // this means that users don't have to cast values between SSE evaluations
  // ane evaluations made via the public variation functions.
  dynamic convertValueByKind(String kind, dynamic value) {
    if (value is String) {
      switch (kind) {
        case 'boolean':
          return value.toLowerCase() == 'true';
        case 'string':
          // Value is already a string, so we just return it
          return value;
        case "int":
          // Number flags can be integer or floating point
          final intValue = int.tryParse(value);
          if (intValue != null) {
            return intValue;
          }
          final doubleValue = double.tryParse(value);
          if (doubleValue != null) {
            return doubleValue;
          }
          break;
        case 'json':
          return _recursiveJsonDecode(value);
      }
    }
    // Return the original value if it's not a string or if the kind is not recognized
    return value;
  }

  dynamic _recursiveJsonDecode(String value, [int depth = 0]) {
    // Safety check: if we're more than 5 levels deep, just return the value
    if (depth > 10) {
      log.severe("Failed to decode Feature Flags JSON flag evaluation value: JSON was escaped more than 10 times, Returning original value: $value");
      return value;
    }
    try {
      dynamic decodedValue = jsonDecode(value);
      if (decodedValue is String) {
        return _recursiveJsonDecode(decodedValue);
      }
      return decodedValue;
    } catch (e) {
      log.severe("Failed to decode Feature Flags JSON flag evaluation value: $e, Returning original value: $value");
      // If decoding fails, return the original value
      return value;
    }
  }

  /// Client's method to deregister and cleanup internal resources used by SDK
  Future<void> destroy() async {
    _listenerSet.clear();
    log.fine('Shutting down Harness Feature Flags SDK Client');
    return _channel.invokeMethod('destroy');
  }
}
