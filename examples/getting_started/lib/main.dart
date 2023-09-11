// @dart=2.12
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ff_flutter_client_sdk/CfClient.dart';
import 'package:logging/logging.dart';

// The SDK API Key to use for authentication.  Configure it when installing the app by setting FF_API_KEY
// e.g..
const apiKey = String.fromEnvironment('FF_API_KEY', defaultValue: '');

const boolFlagName = 'boolflag';
const stringFlagName = "multivariateflag";
const numberFlagName = "numberflag";
const jsonFlagName = "jsonflag";

void main() => runApp(MyApp());

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
  dynamic _boolFlagValue = false;
  dynamic _stringFlagValue = "off";
  dynamic _numberFlagValue = 3;
  dynamic _jsonFlagValue = {};

  @override
  void initState() {
    super.initState();

    // Create Default Configuration for the SDK.  We can use this to disable streaming,
    // change the URL the client connects to etc
    var conf = CfConfigurationBuilder().setLogLevel(Level.FINE).build();

    // Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
    var target = CfTargetBuilder().setIdentifier("fluttersdk").setName("FlutterSDK").build();

    // Init the default instance of the Feature Flag Client
    CfClient.getInstance().initialize(apiKey, conf, target)
        .then((value){
      if (value.success) {
        print("Successfully initialized client");

        // Evaluate flag and set initial state
        CfClient.getInstance().boolVariation("Adasdas", false).then((value) {
          print("$_boolFlagValue: $value");
          setState(() {
            _boolFlagValue = value;
          });
        });

        // Evaluate flag and set initial state
        CfClient.getInstance().jsonVariation("Adasdas", {"aaa": "asdsd"}).then((value) {
          print("$_jsonFlagValue: $value");
          setState(() {
            _jsonFlagValue = value;
          });
        });

        // Evaluate flag and set initial state
        CfClient.getInstance().stringVariation("Adasdas", "default").then((value) {
          print("$_stringFlagValue: $value");
          setState(() {
            _stringFlagValue = value;
          });
        });

        // Evaluate flag and set initial state
        CfClient.getInstance().numberVariation("Adasdas", 1).then((value) {
          print("$_numberFlagValue: $value");
          setState(() {
            _numberFlagValue = value;
          });
        });

        // Setup Event Handler
        listener(data, eventType) {
          print("received event: ${eventType.toString()} with Data: ${data.toString()}");
          switch (eventType) {
            case EventType.EVALUATION_CHANGE:
              String flag = (data as EvaluationResponse).flag;
              dynamic value = (data as EvaluationResponse).value;
              switch(flag) {
                case boolFlagName:
                  setState(() {
                    _boolFlagValue = value;
                  });
                  break;
                case stringFlagName:
                  setState(() {
                    _stringFlagValue = value;
                  });
                  break;
                case numberFlagName:
                  setState(() {
                    _numberFlagValue = value;
                  });
                  break;
                case jsonFlagName:
                  setState(() {
                    _jsonFlagValue = value;
                  });
                  break;
              }
              break;



          // There's been an interruption in the SSE but which has since resumed, which means the
          // cache will have been updated with the latest values, so we can call
          // bool variation to get the most up to date evaluation value.
            case EventType.SSE_RESUME:
              CfClient.getInstance().boolVariation(boolFlagName, false).then((value) {
                print("$boolFlagName: $value");
                setState(() {
                  _boolFlagValue = value;
                });
              });
              break;

            default:
              break;
          }
        }
        CfClient.getInstance().registerEventsListener(listener);
        // CfClient.getInstance().unregisterEventsListener(listener);
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$boolFlagName : $_boolFlagValue", style: const TextStyle(fontSize: 25)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$stringFlagName : $_stringFlagValue", style: const TextStyle(fontSize: 25)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$numberFlagName : $_numberFlagValue", style: const TextStyle(fontSize: 25)),
              ),
              Text("$jsonFlagName : $_jsonFlagValue", style: const TextStyle(fontSize: 25)),
            ],
          ),
        ),
      ),
    );
  }
}
