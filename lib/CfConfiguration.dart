part of ff_flutter_client_sdk;

class CfConfiguration {
  String configUrl;
  String eventUrl;
  bool streamEnabled;
  bool analyticsEnabled;
  int pollingInterval;

  CfConfiguration._builder(CfConfigurationBuilder builder)
      : configUrl = builder._configUrl,
        eventUrl = builder._eventUrl,
        streamEnabled = builder._streamEnabled,
        analyticsEnabled = builder._analyticsEnabled,
        pollingInterval = builder._pollingInterval;

  Map<String, dynamic> _toCodecValue() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['configUrl'] = configUrl;
    result['eventUrl'] = eventUrl;
    result['streamEnabled'] = streamEnabled;
    result['analyticsEnabled'] = analyticsEnabled;
    result['pollingInterval'] = pollingInterval;
    return result;
  }
}

class CfConfigurationBuilder {
  String _configUrl = "https://config.feature-flags.uat.harness.io/api/1.0";
  String _eventUrl = "https://config.feature-flags.uat.harness.io/api/1.0";
  bool _streamEnabled = false;
  bool _analyticsEnabled = true;
  int _pollingInterval = 60;

  CfConfigurationBuilder setConfigUri(String configUrl) {
    this._configUrl = configUrl;
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

  CfConfiguration build() {
    return CfConfiguration._builder(this);
  }
}
