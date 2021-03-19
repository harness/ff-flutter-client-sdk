import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ff_flutter_client_sdk/CfClient.dart';

void main() {
  const MethodChannel channel = MethodChannel('ff_flutter_client_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // expect(await FfFlutterClientSdk.platformVersion, '42');
  });
}
