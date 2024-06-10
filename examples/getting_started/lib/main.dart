// @dart=2.12
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ff_flutter_client_sdk/CfClient.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

const boolFlagName = 'boolflag';
const stringFlagName = "multivariateflag";
const numberFlagName = "numberflag";
const jsonFlagName = "jsonflag";

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harness Flutter SDK Getting Started',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.blue.shade800),
        ),
      ),
      home: FlagState(),
    );
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
    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    // Create Default Configuration for the SDK.  We can use this to disable streaming,
    // change the URL the client connects to etc
    var conf = CfConfigurationBuilder()
        .setLogLevel(Level.FINE)
        .setStreamEnabled(true)
        .setDebugEnabled(true)
        .build();

    // Create a target (different targets can get different results based on rules.  This include a custom attribute 'location')
    var target = CfTargetBuilder()
        .setIdentifier("fluttersdk")
        .setName("FlutterSDK")
        .build();

    var apiKey = dotenv.env['FF_API_KEY'];

    if (apiKey == null) {
      print("API Key missing, exiting FF Sample application");
      return;
    }

    try {
      await initialiseFFClient(apiKey, conf, target);

    } catch (e) {
      print("Initialization failed with error: $e");
      await flagVariations();
    }
  }

  Future<void> destroyFFClient() async {
    await CfClient.getInstance().destroy();
    CfClient.getInstance().unregisterEventsListener(_eventListener);
  }

  Future<void> initialiseFFClient(
      String apiKey, CfConfiguration conf, CfTarget target) async {
    var initResult =
        await CfClient.getInstance().initialize(apiKey, conf, target);
    if (initResult.success) {
      print("Successfully initialized client");

      // Evaluate flags and set initial state
      await flagVariations();

      // Setup Event Handler
      CfClient.getInstance().registerEventsListener(_eventListener);
    } else {
      print("Failed to initialize client, serving defaults");
      await flagVariations();
    }
  }

  void _eventListener(dynamic data, EventType eventType) {
    print("received event: ${eventType.toString()}");
    switch (eventType) {
      case EventType.EVALUATION_CHANGE:
        String flag = (data as EvaluationResponse).flag;

        if (_flagValues.containsKey(flag)) {
          setState(() {
            print(
                "Flag evaluation changed via streaming event: Flag: '$flag', New Evaluation: ${data.value}");
            _flagValues[flag] = data.value;
          });
        }
        break;

      case EventType.EVALUATION_POLLING:
        List<EvaluationResponse> evals = (data as List<EvaluationResponse>);

        for (final eval in evals) {
          if (_flagValues.containsKey(eval.flag)) {
            setState(() {
              _flagValues[eval.flag] = eval.value;
            });
          }
        }
        break;

      case EventType.EVALUATION_DELETE:
        String flag = data;
        print(
            "Flag '$flag' has been deleted, evaluating flags again to fall back to default variation for that flag");
        flagVariations();
        break;

      case EventType.SSE_RESUME:
        flagVariations();
        break;

      default:
        break;
    }
  }

  Future<void> flagVariations() async {
    // Evaluate flag and set initial state
    var boolVariation =
        await CfClient.getInstance().boolVariation(boolFlagName, false);
    setState(() {
      _flagValues[boolFlagName] = boolVariation;
    });

    var jsonVariation =
        await CfClient.getInstance().jsonVariation(jsonFlagName, {});
    setState(() {
      _flagValues[jsonFlagName] = jsonVariation;
    });

    var stringVariation =
        await CfClient.getInstance().stringVariation(stringFlagName, "default");
    setState(() {
      _flagValues[stringFlagName] = stringVariation;
    });

    var numberVariation =
        await CfClient.getInstance().numberVariation(numberFlagName, 1);
    setState(() {
      _flagValues[numberFlagName] = numberVariation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/feature_flags_logo.png',
              fit: BoxFit.cover,
              height: 20, // Adjust the size as needed
            ),
            const SizedBox(width: 8), // Space between logo and title
            const Text('Harness Flutter SDK Getting Started'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  'assets/harness_logo.png',
                  width: 150, // Adjust the width to make the logo smaller
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$boolFlagName : ${_flagValues[boolFlagName]}",
                    style: const TextStyle(fontSize: 15)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$stringFlagName : ${_flagValues[stringFlagName]}",
                    style: const TextStyle(fontSize: 15)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text("$numberFlagName : ${_flagValues[numberFlagName]}",
                    style: const TextStyle(fontSize: 15)),
              ),
              Text("$jsonFlagName : ${_flagValues[jsonFlagName]}",
                  style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
