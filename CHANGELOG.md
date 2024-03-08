## 2.2.0

Fixes and Enhancements:

*  Tidies up behaviour around flag deletion:   Previously, if a flag was deleted, its evaluations would remain in the SDK cache and any variation calls made to it would result in an out-of-date evaluation for your target.
   Exposes new `EVALUATION_DETE` event you can listen for which is emitted when a flag has been deleted.
*  Fixes an issue in iOS where if an evaluation failed, `null` would be returned instead of the default variation that was supplied
*  Upgrades Feature Flags iOS SDK to 1.3.0
*  Upgrades Feature Flags Android SDK to 2.0.2

## 2.1.2

Fixes:

* Fixes Android application crash when using the back button and re-opening the app

Changes:

* Bump `uuid` package to ^4.3.3

## 2.1.1

Changes:

* Adds support for Kotlin version 1.7.x for Android projects. Previously, compilation would fail
due to Kotlin compilation issues.
* Upgrades Feature Flags Android SDK to 1.2.3, which ensures the SDK will not crash the application
should initialization fails. For full details of all Feature Flags Android SDK relases, see: https://github.com/harness/ff-android-client-sdk/releases


## 2.1.0

Changes:

* Flutter Web Support: You can now seamlessly run the SDK across Android, iOS, and Web platforms. 


Fixes and Enhancements:

* Consistent Evaluations: Evaluations fetched through both streaming and polling methods now match the type of evaluations returned by variation.


* iOS Default Object Fix: iOS applications no longer encounter a runtime exception when providing an empty default object to the jsonVariation function.


* Android SSE_RESUME Event: An issue where the SSE_RESUME event wasn't being correctly emitted by the Feature Flags Android SDK has been resolved. We've released an update for the Android SDK to address this, and the Flutter SDK has been updated to use this new version of the Android SDK.


* iOS SDK Update: The Flutter SDK has been updated to use the latest version of the Feature Flags iOS SDK.

## 2.0.0

Changes:
*** Breaking ***
* Updated code to use null safety - requires Flutter 2.0 and Dart 2.12 and newer 
    * See https://dart.dev/null-safety


## 1.0.10

Changes:

* Wrapped Android SDK version updated to 1.0.20 - this release fixes excessive network calls when calling flag evaluation functions


Known issues:

* If internet connectivity is lost and regained, it can take up to 10 seconds for the SSE_RESUME event to fire and for latest evaluations to be reloaded into cache
* SDK Client does not retry if initialization fails. To remediate in the short term, client init may be wrapped in an application's own retry logic.


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
