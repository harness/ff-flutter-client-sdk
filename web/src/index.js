import { initialize } from '@harnessio/ff-javascript-client-sdk';

// declare global {
//   interface Window { FFJavaScriptClientSDK: FFJavaScriptClientSDK; }
// }

class FFJavaScriptClientSDK {
    // Specify a better type if known

    initialize(apiKey, target, options) {
        const result = initialize(apiKey, target, options);
        // Do something with result if needed
    }

    registerEvent(eventType, callback) {
        if (!this.client) return;
        this.client.on(eventType, callback);
    }

    // More functions from the Harness SDK can be wrapped here
}

window.FFJavaScriptClientSDK = "tes";