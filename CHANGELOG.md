## 1.0.9

Changes:

* Adds new event SSE_RESUME event which fires if the application loses and regains internet. When fired this event does two things:
  * Internally reloads all applications into cache.
  * Applications can listen to this event to ensure event listeners don't miss any streamed events during periods of downtime. E.g. call a variation function to get latest evaluation result.
* Wrapped Android SDK version updated to 1.0.19


Known issues:

* If internet connectivity is lost and regained, it can take up to 10 seconds for the SSE_RESUME event to fire and for latest evaluations to be reloaded into cache
* SDK Client does not retry if initialization fails. To remediate in the short term, client init may be wrapped in an application's own retry logic.

## 1.0.8

Fixes:

* Applications no longer crash due to API related exceptions caused by e.g. having no internet connectivity / bad API key etc.
* Streaming now resumes if internet connectivity is lost

Changes:

* Wrapped Android SDK version updated to 1.0.18

Known issues:

* If internet connectivity is lost and a change in flag state has occurred during that period, you must
  disconnect and reconnect to the internet to cache latest changes. Any events streamed after losing connectivity are correctly cached.
* Streaming now resumes if internet connectivity is lost

## 1.0.7f

Fixes:

* Applications no longer crash due to API related exceptions caused by e.g. having no internet connectivity / bad API key etc.
* Streaming now resumes if internet connectivity is lost

Changes:

* Wrapped Android SDK version updated to 1.0.18

Known issues:

* If internet connectivity is lost and a change in flag state has occurred during that period, you must
disconnect and reconnect to the internet to cache latest changes. Any events streamed after losing connectivity are correctly cached.
* SDK Client does not retry if initialization fails. To remediate in the short term, client init may be wrapped in an application's own retry logic.

## 1.0.6
Changes:

* Update README instructions with the current version of the SDK to use

## 1.0.5

Fixes:

* Applications no longer crash due to API related exceptions caused by e.g. having no internet connectivity / bad API key etc. 
The exception message will be returned to the application via the Client initialization auth callback. 

Changes:

* Changed minimum Android API version to 19 
* Wrapped Android SDK version updated to 1.0.17

## 1.0.4

Changes:

* Wrapped Android SDK version updated to 1.0.10.
* Wrapped iOS SDK version updated to 1.0.3.

## 1.0.3

Changes:

* Wrapped Android SDK version updated to 1.0.9.

## 1.0.2

Changes:

* Wrapped Android SDK version updated to 1.0.4.
* Wrapped iOS SDK version updated to 1.0.2.

## 1.0.1

Added support for FF metrics.

## 1.0.0

This release introduces the latest changes and fixes for Android and iOS platforms.
Flutter SDK now targets FF production servers.  

New changes:

* Wrapped Android SDK version updated to 1.0.1.
* Wrapped iOS SDK version updated to 1.0.1.

## 0.0.2

This release introduces the latest changes and fixes for Android and iOS platforms.

New changes:

* Wrapped Android SDK version updated to 0.0.5
* Wrapped iOS SDK version updated to 0.0.6.

## 0.0.1

This is first pubic release of Feature Flags client Flutter client SDK.

New changes:

* Support for initialization and configuration of SDK client
* Feature flag evaluations
* Option to observe for changes of feature flags.
