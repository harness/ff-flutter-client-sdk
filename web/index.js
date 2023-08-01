"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var ff_javascript_client_sdk_1 = require("@harnessio/ff-javascript-client-sdk");
var FFJavaScriptClientSDK = {
    initialize: function (apiKey, target, options) {
        var result = (0, ff_javascript_client_sdk_1.initialize)(apiKey, target, options);
        // Do something with result if needed
    },
    registerEvent: function (eventType, callback) {
        if (!this.client)
            return;
        this.client.on(eventType, callback);
    },
    // More functions from the Harness SDK can be wrapped here
};
window.HarnessFFWeb = FFJavaScriptClientSDK;
