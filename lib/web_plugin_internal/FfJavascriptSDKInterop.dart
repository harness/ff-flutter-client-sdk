@JS()
library rudder_analytics.js;

import 'package:js/js.dart';

@JS("harnessFfFlutterClientSDK.initialize")
external load(String writeKey, String dataPlaneUrl, dynamic options);