// @dart=2.12
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ff_flutter_client_sdk/CfClient.dart';
import 'package:logging/logging.dart';

import 'api_key_provider.dart';

const boolFlagName = 'boolflag';
const stringFlagName = "multivariateflag";
const numberFlagName = "numberflag";
const jsonFlagName = "jsonflag";


// The SDK API Key to use for authentication.
final ApiKeyProvider apiKeyProvider = kIsWeb ? WebApiKeyProvider() : MobileApiKeyProvider();
final apiKey = apiKeyProvider.getApiKey();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Harness Flutter SDK Getting Started', home: FlagState());
  }
}

class FlagState extends StatefulWidget {
  @override
  _FlagState createState() => _FlagState();
}

class _FlagState extends State<FlagState> {
  final Map<String, dynamic> _flagValues = {
    boolFlagName: null,
    stringFlagName: null,
    numberFlagName: null,
    jsonFlagName: null,
  };

  @override
  void initState() {
    super.initState();

    // Create Default Configuration for the SDK.  We can use this to disable streaming,
    // change the URL the client connects to etc
    var conf = CfConfigurationBuilder()
        .setLogLevel(Level.FINE)
        .setStreamEnabled(true)
        .setDebugEnabled(true)
        .setConfigUri("http://localhost:8003/api/1.0")
        .setPollingInterval(60000)
        .build();

    // Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
    var target = CfTargetBuilder()
        .setIdentifier("fluttersdk")
        .setName("FlutterSDK")
        .build();

    // Init the default instance of the Feature Flag Client
    CfClient.getInstance().initialize(apiKey, conf, target).then((initResult) {
      if (initResult.success) {
        print("Successfully initialized client");

        // Evaluate flag and set initial state
        CfClient.getInstance()
            .boolVariation(boolFlagName, false)
            .then((variationResult) {
          setState(() {
            _flagValues[boolFlagName] = variationResult;
          });
        });

        // Evaluate flag and set initial state
        CfClient.getInstance()
            .jsonVariation(jsonFlagName, {}).then((variationResult) {
          setState(() {
            _flagValues[jsonFlagName] = variationResult;
          });
        });

        // Evaluate flag and set initial state
        CfClient.getInstance()
            .stringVariation(stringFlagName, "default")
            .then((variationResult) {
          setState(() {
            _flagValues[stringFlagName] = variationResult;
          });
        });

        // Evaluate flag and set initial state
        CfClient.getInstance()
            .numberVariation(numberFlagName, 1)
            .then((variationResult) {
          setState(() {
            _flagValues[numberFlagName] = variationResult;
          });
        });

        // Setup Event Handler
        listener(data, eventType) {
          print(
              "received event: ${eventType.toString()}");
          switch (eventType) {
            case EventType.EVALUATION_CHANGE:
              String flag = (data as EvaluationResponse).flag;

              if (_flagValues.containsKey(flag)) {
                setState(() {
                  print("Flag evaluation changed via streaming event: Flag: '$flag', New Evaluation: ${data.value}");
                  _flagValues[flag] = data.value;
                });
              }
              break;

            case EventType.EVALUATION_POLLING:
              List<EvaluationResponse> evals =
                  (data as List<EvaluationResponse>);

              for (final eval in evals) {
                if (_flagValues.containsKey(eval.flag)) {
                  setState(() {
                    _flagValues[eval.flag] = eval.value;
                  });
                }
              }
              break;

            // There's been an interruption in the SSE but which has since resumed, which means the
            // cache will have been updated with the latest values.
            // If we have missed any SSE events while the connection has been interrupted, we can call
            // bool variation to get the most up to date evaluation value.
            case EventType.SSE_RESUME:
              // CfClient.getInstance()
              //     .boolVariation(boolFlagName, false)
              //     .then((value) {
              //   print("$boolFlagName: $value");
              //   setState(() {
              //     _flagValues[boolFlagName] = value;
              //   });
              // });
              break;

            default:
              break;
          }
        }

        CfClient.getInstance().registerEventsListener(listener);
        // CfClient.getInstance().destroy();
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
                child: Text("$boolFlagName : ${_flagValues[boolFlagName]}",
                    style: const TextStyle(fontSize: 25)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$stringFlagName : ${_flagValues[stringFlagName]}",
                    style: const TextStyle(fontSize: 25)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$numberFlagName : ${_flagValues[numberFlagName]}",
                    style: const TextStyle(fontSize: 25)),
              ),
              Text("$jsonFlagName : ${_flagValues[jsonFlagName]}",
                  style: const TextStyle(fontSize: 25)),
            ],
          ),
        ),
      ),
    );
  }
}
