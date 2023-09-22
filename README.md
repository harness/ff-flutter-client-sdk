Flutter SDK For Harness Feature Flags
========================

## Table of Contents
**[Intro](#Intro)**<br>
**[Requirements](#Requirements)**<br>
**[Quickstart](#Quickstart)**<br>
**[Further Reading](docs/further_reading.md)**<br>


## Flutter SDK For Harness Feature Flags
Use this README  to get started with our Feature Flags (FF) SDK for Flutter. This guide outlines the basics of getting started with the SDK and provides a full code sample for you to try out.

This sample doesn't include configuration options, for in depth steps and configuring the SDK, for example, disabling streaming or using our Relay Proxy, see the [Flutter SDK Reference](https://docs.harness.io/article/mmf7cu2owg-flutter-sdk-reference).

![FeatureFlags](./docs/images/ff-gui.png)

## Requirements

To use version 2 of the SDK, make sure you've:
- Installed [Flutter SDK >= 2.10.4](https://docs.flutter.dev/get-started/install)
- Minimum Dart SDK is 2.12
- For iOS Apps [Xcode](https://docs.flutter.dev/get-started/install/macos#install-xcode)
- For Android Apps<br> [Android Studio](https://developer.android.com/studio?gclid=CjwKCAjwp7eUBhBeEiwAZbHwkRqdhQkk6wroJeWGu0uGWjW9Ue3hFXc4SuB6lwYU4LOZiZ-MQ4p57BoCvF0QAvD_BwE&gclsrc=aw.ds) or the [Android SDK](docs/dev_environment.md) for CLI only<br>

To use version 1 of the SDK, make sure you've:
- Installed [Flutter SDK >= 2.10.4](https://docs.flutter.dev/get-started/install) 
- Minimum Dark SDK is 2.7
- For iOS Apps [Xcode](https://docs.flutter.dev/get-started/install/macos#install-xcode)
- For Android Apps<br> [Android Studio](https://developer.android.com/studio?gclid=CjwKCAjwp7eUBhBeEiwAZbHwkRqdhQkk6wroJeWGu0uGWjW9Ue3hFXc4SuB6lwYU4LOZiZ-MQ4p57BoCvF0QAvD_BwE&gclsrc=aw.ds) or the [Android SDK](docs/dev_environment.md) for CLI only<br>



You can use Flutter doctor to verify you have the neccessary prerequisites
```shell
flutter doctor
```

To follow along with our test code sample, make sure you've:
- [Created a Feature Flag on the Harness Platform](https://docs.harness.io/article/1j7pdkqh7j-create-a-feature-flag).
- [Created a [server/client] SDK key and made a copy of it](https://docs.harness.io/article/1j7pdkqh7j-create-a-feature-flag#step_3_create_an_sdk_key)

## Install the SDK

### Add the Dependency
Begin by adding the Feature Flag Flutter SDK dependency to your pubspec.yaml file:


```
ff_flutter_client_sdk: ^2.1.0
```

### Import Necessary Packages
Once you've added the dependency, import the necessary packages into your Dart files:

```
import 'package:ff_flutter_client_sdk/CfClient.dart';  
import 'package:ff_flutter_client_sdk/CfConfiguration.dart';  
import 'package:ff_flutter_client_sdk/CfTarget.dart';
```

### SDK Installation for Flutter Web
If you're targeting a Flutter web application:

1. Follow the steps mentioned above to set up the SDK in your project.

2. In addition, embed our JavaScript SDK by adding the following script tag to the `<head>` section of your web page:
```html
  <script src="https://sdk.ff.harness.io/1.19.2/sdk.client-iife.js"></script>
```

This installs our Feature Flags JavaScript SDK and makes it available to your application. Please ensure you regularly upgrade the
JavaScript SDK version to get the latest updates. For the newest JavaScript SDK updates, monitor:

* [JavaScript SDK GitHub Repo](https://github.com/harness/ff-javascript-client-sdk/releases)
* [official Feature Flags Releases Page](https://developer.harness.io/release-notes/feature-flags)

## Code Sample
The following is a complete code example that you can use to test the harnessappdemodarkmode Flag you created on the Harness Platform. When you run the code it will:
1. Connect to the FF service.
2. Report the value of the Flag every 10 seconds until the connection is closed. Every time the `harnessappdemodarkmode` Flag is toggled on or off on the Harness Platform, the updated value is reported.
3. Close the SDK.

To use this sample, copy it into your project and enter your SDK key into the `FF_API_KEY` field.

```Dart
// @dart=2.12.0
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ff_flutter_client_sdk/CfClient.dart';

// The SDK API Key to use for authentication.  Configure it when installing the app by setting FF_API_KEY
// e.g..
const apiKey = String.fromEnvironment('FF_API_KEY', defaultValue: '');

// The flag name
const flagName = String.fromEnvironment('FF_FLAG_NAME', defaultValue: 'harnessappdemodarkmode');

void main() => runApp(MyApp());

// A simple StatelessWidget that fetches the latest value from the FF Service.
// Everytime it receives an update the value of the flag is updated.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Harness Flutter SDK Getting Started', home: FlagState());
  }
}

class FlagState extends StatefulWidget {
  @override
  _FlagState createState() => _FlagState();
}

class _FlagState extends State<FlagState> {
  bool _flagValue = false;

  @override
  void initState() {
    super.initState();

    // Create Default Configuration for the SDK.  We can use this to disable streaming,
    // change the URL the client connects to etc
    var conf = CfConfigurationBuilder().build();

    // Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
    var target = CfTargetBuilder().setIdentifier("fluttersdk").setName("FlutterSDK").build();

    // Init the default instance of the Feature Flag Client
    CfClient.getInstance().initialize(apiKey, conf, target)
        .then((value){
      if (value.success) {
        print("Successfully initialized client");

        // Evaluate flag and set initial state
        CfClient.getInstance().boolVariation(flagName, false).then((value) {
          print("$flagName: $value");
          setState(() {
            _flagValue = value;
          });
        });

        // Setup Event Handler
        CfClient.getInstance().registerEventsListener((data, eventType) {
          print("received event: ${eventType.toString()} with Data: ${data.toString()}");
          switch (eventType) {
                case EventType.EVALUATION_CHANGE:
                    String flag = (data as EvaluationResponse).flag;
                    dynamic value = (data as EvaluationResponse).value;
                    // If the change concerns the flag we care about, then update the state
                    if ( flag == flagName ) {
                        setState(() {
                           _flagValue = value.toLowerCase() == 'true';
                        });
                    }
                    break;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harness Flutter SDK Getting Started'),
      ),
      body: Container(
        child: Center(
          child: new Text("${flagName} : ${_flagValue}", style: TextStyle(fontSize: 25)),
        ),
      ),
    );
  }
}
```

Certainly! Incorporating the recent details into the README section:

---

### Running the Getting Started Example

First, provide your API key in the `.env` [file](examples/getting_started/.env) 

You can then use [Android Studio](https://docs.flutter.dev/tools/android-studio) to run the [getting started example](examples/getting_started) 

You can also run the [getting started example](examples/getting_started) using the Flutter CLI by following these steps:

1. **Prerequisites**:
    - Make sure Flutter is set up on your machine.
    - Decide whether you're targeting an Android emulator, iOS simulator, or a web browser.

2. **Setting Up and Choosing Your Target**:

   **Verification**:
    - To see available devices/emulators:
      ```shell
      flutter devices
      ```
    
   The output will list your devices, for example:
    ```plaintext
    2 connected devices:
    sdk gphone64 x86 64 (mobile) • emulator-5554                        • android-x64    • Android 12 (API 32) (emulator)
    iPhone 13 (mobile)           • 425E99F8-702F-4E15-8BBE-B792BF15ED88 • ios            • com.apple.CoreSimulator.SimRuntime.iOS-15-5 (simulator)
    ```
   

   **Android Emulator**:
    - To start the Android emulator, use:
      ```shell
      $ANDROID_SDK/emulator/emulator @Pixel_4.4_API_32
      ```
      Replace `@Pixel_4.4_API_32` with your own emulator device ID.

    - To run the Flutter app on your Android emulator:
      ```shell
      flutter run -d emulator-5554
      ```

   **iOS Simulator**:
    - To open the iOS simulator:
      ```shell
      open -a simulator
      ```
    - To run the Flutter app on the iOS simulator:
      ```shell
      flutter run -d 425E99F8-702F-4E15-8BBE-B792BF15ED88
      ```



3. **Running the Example on Web**:

   If targeting a web browser, use:
    ```shell
    flutter run -d chrome --hot
    ```

#### Build the project
Using the SDK API key, and a device ID from above you can build and install your app
on a emulator
```shell
cd examples/getting_started
export FF_API_KEY=<your api key>

flutter pub get
flutter run --dart-define=FF_API_KEY=$FF_API_KEY -d <device id>
```

The app should show the configured flags current value. As you toggle the flag in the Harrness UI you will see the value update.
<br><br>

![Alt Text](docs/images/flutter.gif)
<br>

## Additional Reading

For further examples and config options, see the [Flutter SDK Reference](https://docs.harness.io/article/mmf7cu2owg-flutter-sdk-reference) and the [test Flutter project](https://github.com/harness/ff-flutter-client-sdk/blob/main/examples/getting_started/lib/main.dart).

[Further Reading](docs/further_reading.md)<br>
[Getting Started Example](examples/getting_started)<br>
[Advanced Example](https://github.com/drone/ff-flutter-client-sample)

For more information about Feature Flags, see our [Feature Flags documentation](https://docs.harness.io/article/0a2u2ppp8s-getting-started-with-feature-flags).
