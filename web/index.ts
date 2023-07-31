import { initialize, Event } from '@harnessio/ff-javascript-client-sdk'

declare global {
  interface Window { HarnessFFWeb: any; }
}

var HarnessFFWeb = {
  initialize: function(apiKey, target, options) {
    var result = initialize(apiKey, target, options);
    // Do something with result if needed
  },

  registerEvent: function(eventType, callback) {
    if (!this.client) return;
    this.client.on(eventType, callback);
  },

  // More functions from the Harness SDK can be wrapped here
};

window.HarnessFFWeb = HarnessFFWeb;