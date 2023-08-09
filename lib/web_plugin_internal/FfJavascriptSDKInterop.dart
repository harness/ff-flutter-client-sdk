@JS()
library harness_javascript_sdk.js;

import 'package:js/js.dart';

// HarnessFFSDK is the global name that the JavaScript SDK sets in its iife distribution, which
// we ask users to import.
@JS("HarnessFFSDK.initialize")
external dynamic initialize(String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);