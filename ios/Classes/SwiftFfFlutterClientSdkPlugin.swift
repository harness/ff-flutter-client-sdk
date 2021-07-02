import Flutter
import UIKit
import ff_ios_client_sdk

public class SwiftFfFlutterClientSdkPlugin: NSObject, FlutterPlugin {
	private var channel : FlutterMethodChannel
	private var hostChannel : FlutterMethodChannel

	init(channel: FlutterMethodChannel, hostChannel: FlutterMethodChannel) {
		self.channel = channel
		self.hostChannel = hostChannel
	}

	public static func register(with registrar: FlutterPluginRegistrar) {
		let channel = FlutterMethodChannel(name: "ff_flutter_client_sdk", binaryMessenger: registrar.messenger())
		let hostChannel = FlutterMethodChannel(name: "cf_flutter_host", binaryMessenger: registrar.messenger())
		let instance = SwiftFfFlutterClientSdkPlugin(channel: channel, hostChannel: hostChannel)
		registrar.addMethodCallDelegate(instance, channel: channel)
	}

	//Extract CfConfiguration from dictionary
	func configFrom(dict: Dictionary<String, Any?>) -> CfConfiguration {

		let configBuilder = CfConfiguration.builder()
		if let configUrl = dict["configUrl"] as? String {
			_ = configBuilder.setConfigUrl(configUrl)
		}
		if let streamUrl = dict["streamUrl"] as? String {
			_ = configBuilder.setStreamUrl(streamUrl)
		}
		if let eventUrl = dict["eventUrl"] as? String {
            _ = configBuilder.setEventUrl(eventUrl)
        }
		if let streamEnabled = dict["streamEnabled"] as? Bool {
			_ = configBuilder.setStreamEnabled(streamEnabled)
		}
		if let analitycsEnabled = dict["analyticsEnabled"] as? Bool {
			_ = configBuilder.setAnalyticsEnabled(analitycsEnabled)
		}
		if let pollingInterval = dict["pollingInterval"] as? TimeInterval {
			_ = configBuilder.setPollingInterval(pollingInterval)
		}
		return configBuilder.build()
	}

	//Extract CfTarget from dictionary
	func targetFrom(dict: Dictionary<String, Any?>) -> CfTarget {
		let targetBuilder = CfTarget.builder()
		if let identifier = dict["identifier"] as? String {
			_ = targetBuilder.setIdentifier(identifier)
		}
		if let name = dict["name"] as? String {
			_ = targetBuilder.setName(name)
		}
		if let anonymous = dict["anonymous"] as? Bool {
			_ = targetBuilder.setAnonymous(anonymous)
		}
		if let attributes = dict["attributes"] as? [String:String] {
			_ = targetBuilder.setAttributes(attributes)
		}
		return targetBuilder.build()
	}

	enum FlutterMethodCallIdentifiers: String {
		case initialize
		case registerEventsListener
		case stringVariation
		case boolVariation
		case numberVariation
		case jsonVariation
		case destroy
	}

	enum EventTypeId: String {
		case start
		case end
		case evaluationPolling = "evaluation_polling"
		case evaluationChange  = "evaluation_change"
	}

	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		let args = call.arguments as? Dictionary<String, Any>
		guard let methodCallId = FlutterMethodCallIdentifiers(rawValue: call.method) else {
			result(nil)
			print("No such FlutterMethodCall exists, please check for typos.")
			return
		}

		switch  methodCallId {
			case .initialize:
				let apiKey = args?["apiKey"] as! String
				let config = configFrom(dict: args?["configuration"] as! Dictionary<String, Any>)
				let target = targetFrom(dict: args?["target"] as! Dictionary<String, Any>)

				CfClient.sharedInstance.initialize(apiKey: apiKey, configuration: config, target: target) {res in
					switch res {
						case .failure(_): result(false)
						case .success: result(true)
					}
				}

			case .registerEventsListener:
				CfClient.sharedInstance.registerEventsListener() { eventType in
					switch eventType {
						case .failure(_):
							DispatchQueue.main.async {
								self.hostChannel.invokeMethod(EventTypeId.end.rawValue, arguments: nil);
							}
						case .success(let eventType):
							switch eventType {
								case .onOpen:
									DispatchQueue.main.async {
										self.hostChannel.invokeMethod(EventTypeId.start.rawValue, arguments:nil);
									}
								case .onComplete:
									DispatchQueue.main.async {
										self.hostChannel.invokeMethod(EventTypeId.end.rawValue, arguments: nil);
									}
								case .onPolling(let evals):
									guard let evals = evals else { result(nil); return }

									let evaluationArray = evals.map { eval -> [String:Any] in
										let value = self.extractValue(eval.value)
										return ["flag": eval.flag, "value": value ?? ""]
									}

									let content = ["evaluationData": evaluationArray]

									DispatchQueue.main.async {
										self.hostChannel.invokeMethod(EventTypeId.evaluationPolling.rawValue, arguments: content)
									}

								case .onEventListener(let eval):
									guard let eval = eval else { result(nil); return }

									let value = self.extractValue(eval.value)
									let content = ["flag": eval.flag, "value": value ?? ""]

									DispatchQueue.main.async {
										self.hostChannel.invokeMethod(EventTypeId.evaluationChange.rawValue, arguments: content)
									}

								case .onMessage(_): result("Message received");
							}
					}
				}

			case .stringVariation:
				CfClient.sharedInstance.stringVariation(evaluationId: args?["flag"] as! String, defaultValue: args?["value"] as? String) { (evaluation) in
					guard let evaluation = evaluation else {return}
					result(evaluation.value.stringValue)
				}

			case .boolVariation:
				CfClient.sharedInstance.boolVariation(evaluationId: args?["flag"] as! String, defaultValue: args?["value"] as? Bool) { (evaluation) in
					guard let evaluation = evaluation else {return}
					result(evaluation.value.boolValue)
				}

			case .numberVariation:
				CfClient.sharedInstance.numberVariation(evaluationId: args?["flag"] as! String, defaultValue: args?["value"] as? Int) { (evaluation) in
					guard let evaluation = evaluation else {return}
					result(Double(evaluation.value.intValue ?? 0))
				}

			case .jsonVariation:
				let val = args?["defaultValue"] as? [String:Any]
				guard let defaultObject = val else { break }
				let key = defaultObject.keys.first!
				let value = defaultObject[key]
				let valueType: ValueType = determineType(value)

				CfClient.sharedInstance.jsonVariation(evaluationId: args?["flag"] as! String, defaultValue: [key:valueType]) { (evaluation) in
					guard let evaluation = evaluation else {return}
					if let value = evaluation.value.stringValue {
						result(self.parseJson(from: value))
					}
				}

			case .destroy:
				CfClient.sharedInstance.destroy()
		}
	}

	func determineType(_ value: Any?) -> ValueType {
		if value is String {
			return ValueType.string(value as! String)
		} else if value is Bool {
			return ValueType.bool(value as! Bool)
		} else if value is Int {
			return ValueType.int(value as! Int)
		} else {
			let subObj = value as! [String:Any]
			let key = subObj.keys.first!
			let subVal = subObj[key]
			let valueType = determineType(subVal)
			return ValueType.object([key:valueType])
		}
	}

	func extractValue(_ valueType :ValueType) -> Any? {
		switch valueType {
			case .string(let string): return string
			case .bool(let bool): return bool
			case .int(let int): return int
			case .object(let object): return object
		}
	}

	func parseJson(from string: String) -> [String:Any] {
		guard let data = string.data(using: .utf8, allowLossyConversion: false) else {return [:]}
		do {
			if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] {
				return json
			}
		} catch {
			print("Not a Valid JSON")
		}
		return [:]
	}
}
