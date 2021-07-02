part of ff_flutter_client_sdk;

class CfTarget {

  String name;
  String identifier;
  bool anonymous;
  Map<String, String> attributes;

  CfTarget._builder(CfTargetBuilder builder)
      : identifier = builder._identifier,
        name = builder._name,
        anonymous = builder._anonymous,
        attributes = builder._attributes;

  Map<String, dynamic> _toCodecValue() {

    final Map<String, dynamic> result = <String, dynamic>{};
    result['identifier'] = identifier;
    result['name'] = name;
    result['anonymous'] = anonymous;
    result['attributes'] = attributes;
    return result;
  }
}

class CfTargetBuilder {
  String _identifier = "";
  String _name = "";
  bool _anonymous = false;
  Map<String, String> _attributes = new Map();

  CfTargetBuilder setIdentifier(String identifier) {
    this._identifier = identifier;
    return this;
  }

  CfTargetBuilder setName(String name) {
    this._name = name;
    return this;
  }

  CfTargetBuilder setAnonymous(bool anonymous) {
    this._anonymous = anonymous;
    return this;
  }

  CfTargetBuilder setAttributes(String key, String value) {
    this._attributes[key] = value;
    return this;
  }

  CfTarget build() {
    return CfTarget._builder(this);
  }
}
