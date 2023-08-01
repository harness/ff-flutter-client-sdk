import { initialize, Event } from '@harnessio/ff-javascript-client-sdk'

declare global {
  interface Window { Client: any; }
}

class FFJavaScriptClientSDK {
  client: any; // Specify a better type if known

  initialize(apiKey: string, target: any, options: any): void {
    const result = initialize(apiKey, target, options);
    // Do something with result if needed
  }

  registerEvent(eventType: string, callback: Function): void {
    if (!this.client) return;
    this.client.on(eventType, callback);
  }

  // More functions from the Harness SDK can be wrapped here
}

window.Client = new FFJavaScriptClientSDK();
