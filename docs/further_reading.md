# Further Reading

Covers advanced topics (different config options and scenarios)

## Configuration Options
The following configuration options are available to control the behaviour of the SDK.
You can pass the configuration in as options when the SDK client is created.
```dart
// Flutter SDK Config
var conf = CfConfigurationBuilder()
        .setConfigUri("https://config.ff.harness.io/api/1.0")
        .setEventUrl("https://events.ff.harness.io/api/1.0")
        .setPollingInterval(60)
        .setStreamEnabled(true)
        .setAnalyticsEnabled(true)
        .build();
```

| Name            | Config Option                                            | Description                                                                                                                                      | default                              |
|-----------------|----------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| baseUrl         | setConfigUri("https://config.ff.harness.io/api/1.0")     | the URL used to fetch feature flag evaluations. You should change this when using the Feature Flag proxy to http://localhost:7000                | https://config.ff.harness.io/api/1.0 |
| eventsUrl       | setEventUrl("https://events.ff.harness.io/api/1.0"),     | the URL used to post metrics data to the feature flag service. You should change this when using the Feature Flag proxy to http://localhost:7000 | https://events.ff.harness.io/api/1.0 |
| pollInterval    | setPollingInterval(60)                                   | when running in stream mode, the interval in seconds that we poll for changes.                                                                   | 60                                   |
| enableStream    | setStreamEnabled(True),                                  | Enable streaming mode.                                                                                                                           | true                                 |
| enableAnalytics | setAnalyticsEnabled(True)                                | Enable analytics.  Metrics data is posted every 60s                                                                                              | true                                 |

## **_Initialization_**
`CfClient` is base class that provides all thefeatures of SDK.

```Dart
final conf = CfConfigurationBuilder()
    .setStreamEnabled(true)
    .setPollingInterval(60) //time in seconds (minimum value is 60)
    .build();
final target = CfTargetBuilder().setIdentifier(name).build();

final res = await CfClient.getInstance().initialize(apiKey, conf, target);
```
`target` represents a desired target for which we want features to be evaluated.

`"YOUR_API_KEY"` is an authentication key, needed for access to Harness services.

**Your Harness SDK is now initialized. Congratulations!!!**
<br><br>
### **_Public API Methods_** ###
The Public API exposes a few methods that you can utilize:

* `static Future<InitializationResult> initialize(String apiKey, CfConfiguration configuration, CfTarget target)`

* `static Future<bool> boolVariation(String evaluationId, bool defaultValue)`

* `static Future<String> stringVariation(String evaluationId, String defaultValue)`

* `static Future<double> numberVariation(String evaluationId, double defaultValue)`

* `static Future<Map<dynamic, dynamic>> jsonVariation(String evaluationId, Map<dynamic, dynamic> defaultValue)`

* `static Future<void> registerEventsListener(CfEventsListener listener) `

* `static Future<void> unregisterEventsListener(CfEventsListener listener) `

* `static Future<void> destroy()`
  <br><br>


## Fetch evaluation's value
It is possible to fetch a value for a given evaluation. Evaluation is performed based on different type. In case there is no evaluation with provided id, the default value is returned.

Use appropriate method to fetch the desired Evaluation of a certain type.
### <u>_boolVariation(String evaluationId, bool defaultValue)_</u>

```Dart
//get boolean evaluation
final evaluation = await CfClient.getInstance().boolVariation("demo_bool_evaluation", false);
```
### <u>_numberVariation(String evaluationId, double defaultValue)_</u>
```Dart
//get number evaluation
final numberEvaluation = await CfClient.getInstance().numberVariation("demo_number_evaluation", 0);
```

### <u>_stringVariation(String evaluationId, String defaultValue)_</u>
```Dart
//get string evaluaation
final stringEvaluation = await CfClient.getInstance().stringVariation("demo_string_evaluation", "default");
```
### <u>_jsonVariation(String evaluationId, Map<dynamic, dynamic> defaultValue)_</u>
```Dart
//get json evaluation
final jsonEvaluation = await CfClient.getInstance().jsonVariation("demo_json_evaluation", {});

```

## _Register for events_
This method provides a way to register a listener for different events that might be triggered by SDK, indicating specific change in SDK itself.

```Dart
    CfClient.getInstance().registerEventsListener((EvaluationResponse, EventType) {
     
    });

```

Triggered event will have one of the following types.

```Dart
enum EventType {
    SSE_START,
    SSE_END,
    EVALUATION_POLLING,
    EVALUATION_CHANGE
}
```

Each type will return a corresponding value as shown in the table below.
```Dart
| EventType          | Returns                  |
| :----------------  | :-----------------------:|
| SSE_START          | null                     |
| SSE_END            | null                     |
| EVALUATION_POLLING | List<EvaluationResponse> |
| EVALUATION_CHANGE  | EvaluationResponse       |

```
Visit documentation for complete list of possible types and values they provide.

To avoid unexpected behaviour, when listener is not needed anymore, a caller should call
`CfClient.getInstance().unregisterEventsListener(eventsListener)`
This way the sdk will remove desired listener from internal list.

## _Shutting down the SDK_
To avoid potential memory leak, when SDK is no longer needed (when the app is closed, for example), a caller should call this method
```Dart
CfClient.getInstance().destroy()
```
