@JS()
library harness_javascript_sdk.js;

import 'package:js/js.dart';

// The window reference to the JavaScript SDK, which we use before it's
// initialized.
const sdkWindowReference = 'HarnessFFSDK';
// Exposed by the JavaScript SDK
const sdkInitialize = 'initialize';
const sdkEvent = 'Event';

// Once we've initialized the Client, we set it as a property on the window using
// this reference
const clientWindowReference = 'cfClient';
// Exposed by the initialized client instance
const clientOn = 'on';
const clientOff = 'off';
const clientVariation = 'variation';
const clientClose = 'close';

// HarnessFFSDK is the global name that the JavaScript SDK sets in its iife distribution, which
// we ask users to import.
@JS("$sdkWindowReference.$sdkInitialize")
external dynamic initialize(
    String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);

@JS('$clientWindowReference.$clientOn')
external dynamic on(
    String apiKey, Map<String, dynamic> target, Map<String, dynamic> options);
