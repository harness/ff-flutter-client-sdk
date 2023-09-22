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
      }
      return false;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('placeholder', () async {
    expect(true, true);
  });

  // FIXME:
  // test('initializeMethod', () async {
  //   expect((await CfClient.initialize("", CfConfigurationBuilder().build(), CfTargetBuilder().build())).success, true);
  // });
  //
  // test('stringVariation', () async {
  //   expect((await CfClient.stringVariation("demo_first_id", "demo_value")), "first_value");
  //   expect((await CfClient.stringVariation("demo_empty_id", "demo_value")), "demo_value");
  // });
  // test('boolVariation', () async {
  //   expect((await CfClient.boolVariation("demo_first_bool_id", false)), true);
  //   expect((await CfClient.boolVariation("demo_second_bool_id", false)), false);
  // });

}
