// @dart=2.9
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ff_flutter_client_sdk/CfClient.dart';

// The SDK API Key to use for authentication.  Configure it when installing the app by setting FF_API_KEY
// e.g..
const apiKey = String.fromEnvironment('FF_API_KEY', defaultValue: '');

// flagName is the identifier of the flag to evaluate
const flagName = String.fromEnvironment('FF_FLAG_NAME', defaultValue: 'harnessappdemodarkmode');

// Setup App
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
          // There's been an interruption in the SSE but which has since resumed, which means the
          // cache will have been updated with the latest values, so we can call
          // bool variation to get the most up to date evaluation value.
            case EventType.SSE_RESUME:
              CfClient.getInstance().boolVariation(flagName, false).then((value) {
                print("$flagName: $value");
                setState(() {
                  _flagValue = value;
                });
              });
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
