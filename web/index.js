"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var ff_javascript_client_sdk_1 = require("@harnessio/ff-javascript-client-sdk");
var FFJavaScriptClientSDK = /** @class */ (function () {
    function FFJavaScriptClientSDK() {
    }
    FFJavaScriptClientSDK.prototype.initialize = function (apiKey, target, options) {
        var result = (0, ff_javascript_client_sdk_1.initialize)(apiKey, target, options);
        // Do something with result if needed
    };
    FFJavaScriptClientSDK.prototype.registerEvent = function (eventType, callback) {
        if (!this.client)
            return;
        this.client.on(eventType, callback);
    };
    return FFJavaScriptClientSDK;
}());
window.Client = new FFJavaScriptClientSDK();
