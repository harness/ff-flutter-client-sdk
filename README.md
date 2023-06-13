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
- Installed [Flutter SDK >= 2.0.0](https://docs.flutter.dev/get-started/install)
- Installed Dart 2.12.0 or newer
- For iOS Apps [Xcode](https://docs.flutter.dev/get-started/install/macos#install-xcode)
- For Android Apps<br> [Android Studio](https://developer.android.com/studio?gclid=CjwKCAjwp7eUBhBeEiwAZbHwkRqdhQkk6wroJeWGu0uGWjW9Ue3hFXc4SuB6lwYU4LOZiZ-MQ4p57BoCvF0QAvD_BwE&gclsrc=aw.ds) or the [Android SDK](docs/dev_environment.md) for CLI only<br>

To use version 1 of the SDK, make sure you've:
- Installed [Flutter SDK >= 2.10.4](https://docs.flutter.dev/get-started/install) 
- Installed Dart 2.10.5 or older
- For iOS Apps [Xcode](https://docs.flutter.dev/get-started/install/macos#install-xcode)
- For Android Apps<br> [Android Studio](https://developer.android.com/studio?gclid=CjwKCAjwp7eUBhBeEiwAZbHwkRqdhQkk6wroJeWGu0uGWjW9Ue3hFXc4SuB6lwYU4LOZiZ-MQ4p57BoCvF0QAvD_BwE&gclsrc=aw.ds) or the [Android SDK](docs/dev_environment.md) for CLI only<br>



You can use Flutter doctor to verify you have the neccessary prerequisites
```shell
flutter doctor
```

To follow along with our test code sample, make sure you've:
- [Created a Feature Flag on the Harness Platform](https://docs.harness.io/article/1j7pdkqh7j-create-a-feature-flag).
- [Created a [server/client] SDK key and made a copy of it](https://docs.harness.io/article/1j7pdkqh7j-create-a-feature-flag#step_3_create_an_sdk_key)

## Installing the SDK
To add the SDK to your own project run
```Dart
ff_flutter_client_sdk: ^1.0.11
```

Then, you may import package to your project
```Dart
import 'package:ff_flutter_client_sdk/CfClient.dart';
```

## Code Sample
The following is a complete code example that you can use to test the harnessappdemodarkmode Flag you created on the Harness Platform. When you run the code it will:
1. Connect to the FF service.
2. Report the value of the Flag every 10 seconds until the connection is closed. Every time the `harnessappdemodarkmode` Flag is toggled on or off on the Harness Platform, the updated value is reported.
3. Close the SDK.

To use this sample, copy it into your project and enter your SDK key into the `FF_API_KEY` field.

```Dart
// @dart=2.9
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

### Running the example
If you want to run the [getting started example](examples/getting_started), then you can use flutter to on the cli.
You just need to have either an Android or iOS emulator running.

To start an android emulator run (replace @Pixel_4.4_API_32 with your own device id)
```
$ANDROID_SDK/emulator/emulator @Pixel_4.4_API_32
```

or for iOS run

```shell
open -a simulator
```

Confirm you have an iOS or Android device with
```shell
flutter devices
2 connected devices:

sdk gphone64 x86 64 (mobile) • emulator-5554                        • android-x64    • Android 12 (API 32) (emulator)
iPhone 13 (mobile)           • 425E99F8-702F-4E15-8BBE-B792BF15ED88 • ios            • com.apple.CoreSimulator.SimRuntime.iOS-15-5 (simulator)
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
