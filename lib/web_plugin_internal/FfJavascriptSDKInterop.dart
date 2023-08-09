@JS()
library harness_javascript_sdk.js;

import 'package:ff_flutter_client_sdk/CfClient.dart';
import 'package:js/js.dart';

// HarnessFFSDK is the global name that the JavaScript SDK sets in its iife distribution, which
// we ask users to import.
@JS("HarnessFFSDK.initialize")
external dynamic initialize(String apiKey, dynamic target, dynamic options);