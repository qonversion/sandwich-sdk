import Foundation
#if os(iOS)
import Qonversion

extension NoCodesAction {
    func toMap() -> BridgeData {
        return [
            "type": type.toString(),
            "parameters": parameters
        ]
    }
}

extension NoCodesActionType {
    func toString() -> String {
        switch self {
        case .url: return "url"
        case .deeplink: return "deeplink"
        case .navigation: return "navigate"
        case .purchase: return "purchase"
        case .restore: return "restore"
        case .close: return "close"
        case .closeAll: return "closeAll"
        default: return "unknown"
        }
    }
}

extension NoCodesPresentationStyle {
    static func fromString(_ key: String?) -> NoCodesPresentationStyle? {
        switch (key) {
        case "Push":
            return NoCodesPresentationStyle.push
        case "FullScreen":
            return NoCodesPresentationStyle.fullScreen
        case "Popover":
            return NoCodesPresentationStyle.popover
        default:
            return nil
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func toPresentationConfig() -> NoCodesPresentationConfiguration {
        guard let presentationStyleStr = self["presentationStyle"] as? String,
              let presentationStyle = NoCodesPresentationStyle.fromString(presentationStyleStr)
        else { return NoCodesPresentationConfiguration.defaultConfiguration() }

        var animated = true
        
        if let animatedFromString = (self["animated"] as? String)?.toBool() {
            animated = animatedFromString
        } else if let animatedFromConfig = self["animated"] as? Bool {
            animated = animatedFromConfig
        }

        return NoCodesPresentationConfiguration(animated: animated, presentationStyle: presentationStyle)
    }
}

extension NoCodesError {

  func toMap() -> BridgeData {
    let codes = [
      NoCodesErrorType.unknown: "Unknown",
      NoCodesErrorType.`internal`: "Internal",
      NoCodesErrorType.authorizationFailed: "AuthorizationFailed",
      NoCodesErrorType.critical: "Critical",
      NoCodesErrorType.invalidRequest: "BadNetworkRequest",
      NoCodesErrorType.invalidResponse: "BadResponse",
      NoCodesErrorType.productNotFound: "ProductNotFound",
      NoCodesErrorType.productsLoadingFailed: "ProductsLoadingFailed",
      NoCodesErrorType.rateLimitExceeded: "RateLimitExceeded",
      NoCodesErrorType.screenLoadingFailed: "ScreenLoadingFailed",
      NoCodesErrorType.sdkInitializationError: "SDKInitializationError"
    ]
    
    var code = codes[type]
    var errorData: BridgeData? = nil
    
    if let nsError = error as? NSError, nsError.domain == QonversionErrorDomain {
      code = "QonversionError"
      errorData = nsError.toMap()
    }

    return [
      "code": code,
      "description": message,
      "additionalMessage": additionalInfo?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "",
      "qonversionError": errorData,
    ]
  }
}

public func errorToMap(_ error: Error?) -> BridgeData? {
    var payload: BridgeData? = nil
    if let error = error as? NoCodesError {
        payload = error.toMap()
    } else if let error = error as? NSError {
        payload = error.toMap()
    }
    
    return payload
}

#endif
