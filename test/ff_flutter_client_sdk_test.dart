import 'package:ff_flutter_client_sdk/CfClient.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('ff_flutter_client_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch(methodCall.method) {
        case "initialize":
          return true;
        case "boolVariation":
          Map<dynamic, dynamic> args = methodCall.arguments;
          String flag = args["flag"];
          switch (flag) {
            case "demo_first_bool_id":
              return true;
            case "demo_second_bool_id":
              return false;
          }
          break;
        case "stringVariation":
          Map<dynamic, dynamic> args = methodCall.arguments;
          String flag = args["flag"];
          String defaultValue = args["defaultValue"];
          switch (flag) {
            case "demo_first_id":
              return "first_value";
            case "demo_empty_id":
              return "demo_value";
            default:
              return defaultValue;
          }
        case "jsonVariation":
          Map<dynamic, dynamic> args = methodCall.arguments;
          String flag = args["flag"];
          Map<dynamic, dynamic> defaultValue = args["defaultValue"];
          switch (flag) {
            case "demo_json_id":
              return {"key": "json_value"};
            default:
              return defaultValue;
          }
        case "numberVariation":
          Map<dynamic, dynamic> args = methodCall.arguments;
          String flag = args["flag"];
          double defaultValue = args["defaultValue"];
          switch (flag) {
            case "demo_number_id":
              return 42.0;
            default:
              return defaultValue;
          }
      }
      return false;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('initializeMethod', () async {
    expect((await CfClient.getInstance().initialize("", CfConfigurationBuilder().build(), CfTargetBuilder().build())).success, true);
  });

  test('stringVariation', () async {
    expect((await CfClient.getInstance().stringVariation("demo_first_id", "demo_value")), "first_value");
    expect((await CfClient.getInstance().stringVariation("demo_empty_id", "demo_value")), "demo_value");
  });

  test('boolVariation', () async {
    expect((await CfClient.getInstance().boolVariation("demo_first_bool_id", false)), true);
    expect((await CfClient.getInstance().boolVariation("demo_second_bool_id", false)), false);
  });

  test('jsonVariation', () async {
    expect((await CfClient.getInstance().jsonVariation("demo_json_id", {"key": "default"})), {"key": "json_value"});
    expect((await CfClient.getInstance().jsonVariation("non_existing_json_id", {"key": "default"})), {"key": "default"});
  });

  test('numberVariation', () async {
    expect((await CfClient.getInstance().numberVariation("demo_number_id", 0.0)), 42.0);
    expect((await CfClient.getInstance().numberVariation("non_existing_number_id", 0.0)), 0.0);
  });
}
