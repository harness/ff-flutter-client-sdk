"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var ff_javascript_client_sdk_1 = require("@harnessio/ff-javascript-client-sdk");
var HarnessFFWeb = {
    initialize: function (apiKey, target, options) {
        var result = (0, ff_javascript_client_sdk_1.initialize)(apiKey, target, options);
        // Do something with result if needed
    },
    // More functions from the Harness SDK can be wrapped here
};
window.HarnessFFWeb = HarnessFFWeb;
