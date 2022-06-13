Harness CF Flutter SDK Example usage
========================

## _Setup_

To install SDK, declare a dependency to project's `pubspec.yaml` file:
```Dart
ff_flutter_client_sdk: ^1.0.3
```

Then, you may import package to your project
```Dart
import 'package:ff_flutter_client_sdk/CfClient.dart';
```

After this step, the SDK elements, primarily `CfClient`, should be accessible in main application.

## **_Example_**

```Dart
final conf = CfConfigurationBuilder()
    .setStreamEnabled(true)
    .setPollingInterval(60) //time in seconds (minimum value is 60)
    .build();
final target = CfTargetBuilder().setIdentifier(name).build();

final res = await CfClient.initialize(apiKey, conf, target);


//get number evaluation
final numberEvaluation = await CfClient.numberVariation("demo_number_evaluation", 0);

//get string evaluaation
final stringEvaluation = await CfClient.stringVariation("demo_string_evaluation", "default");

//get json evaluation
final jsonEvaluation = await CfClient.jsonVariation("demo_json_evaluation", {});

CfClient.registerEventsListener((responseData, eventType) {
    _eventListener = (responseData, eventType){};
    switch (eventType) {
      case EventType.SSE_START:
        print("Started SSE");
        break;
      case EventType.SSE_END:
        print("SSE Completed");
        break;
      case EventType.EVALUATION_CHANGE:
        String flag = (responseData as EvaluationResponse).flag;
        dynamic value = (responseData as EvaluationResponse).value;

        break;
      case EventType.EVALUATION_POLLING:
        List pollingResult = responseData;

        pollingResult.forEach((element) {
          String flag = (element as EvaluationResponse).flag;
          dynamic value = (element as EvaluationResponse).value;

        });
        break;
    }
});

//Shutting down SDK
CfClient.destroy()

```
