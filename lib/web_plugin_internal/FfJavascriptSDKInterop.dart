@JS()
library rudder_analytics.js;

import 'package:js/js.dart';

// HarnessFFSDK is the global name that the JavaScript SDK sets in its iife distribution, which
// we ask users to import. 
@JS("HarnessFFSDK.initialize")
external load(String writeKey, String dataPlaneUrl, dynamic options);