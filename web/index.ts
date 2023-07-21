import { initialize, Event } from '@harnessio/ff-javascript-client-sdk'

declare global {
  interface Window { HarnessFFWeb: any; }
}

var HarnessFFWeb = {
  initialize: function(apiKey, target, options) {
    var result = initialize(apiKey, target, options);
    // Do something with result if needed
  },

  // More functions from the Harness SDK can be wrapped here
};

window.HarnessFFWeb = HarnessFFWeb;