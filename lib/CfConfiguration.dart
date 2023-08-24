part of ff_flutter_client_sdk;

class CfConfiguration {
  String configUrl;
  String streamUrl;
  String eventUrl;
  bool streamEnabled;
  bool analyticsEnabled;
  int pollingInterval;
  // We use logLevel in CfClient.dart only, so no need to get a codec value
  Level logLevel;

  CfConfiguration._builder(CfConfigurationBuilder builder)
      : configUrl = builder._configUrl,
        streamUrl = builder._streamUrl,
        eventUrl = builder._eventUrl,
        streamEnabled = builder._streamEnabled,
        analyticsEnabled = builder._analyticsEnabled,
        pollingInterval = builder._pollingInterval,
        logLevel = builder._logLevel;

  Map<String, dynamic> _toCodecValue() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['configUrl'] = configUrl;
    result['streamUrl'] = streamUrl;
    result['eventUrl'] = eventUrl;
    result['streamEnabled'] = streamEnabled;
    result['analyticsEnabled'] = analyticsEnabled;
    result['pollingInterval'] = pollingInterval;
    return result;
  }
}

class CfConfigurationBuilder {
  String _configUrl = "https://config.ff.harness.io/api/1.0";
  String _streamUrl = "https://config.ff.harness.io/api/1.0/stream";
  String _eventUrl = "https://events.ff.harness.io/api/1.0";
  bool _streamEnabled = true;
  bool _analyticsEnabled = true;
  int _pollingInterval = 60;
  Level _logLevel = Level.SEVERE;

  CfConfigurationBuilder setConfigUri(String configUrl) {
    this._configUrl = configUrl;
    return this;
  }

  CfConfigurationBuilder setStreamUrl(String streamUrl) {
    this._streamUrl = streamUrl;
    return this;
  }

  CfConfigurationBuilder setEventUrl(String eventUrl) {
    this._eventUrl = eventUrl;
    return this;
  }

  CfConfigurationBuilder setStreamEnabled(bool streamEnabled) {
    this._streamEnabled = streamEnabled;
    return this;
  }

  CfConfigurationBuilder setAnalyticsEnabled(bool analyticsEnabled) {
    this._analyticsEnabled = analyticsEnabled;
    return this;
  }

  CfConfigurationBuilder setPollingInterval(int pollingInterval) {
    this._pollingInterval = pollingInterval;
    return this;
  }

  CfConfigurationBuilder setLogLevel(Level logLevel) {
    this._logLevel = logLevel;
    return this;
  }

  CfConfiguration build() {
    return CfConfiguration._builder(this);
  }
}
