import Foundation
#if os(iOS)
import NoCodes
import Qonversion

extension NoCodes.Action {
    func toMap() -> BridgeData {
        return [
            "type": type.toString(),
            "parameters": parameters
        ]
    }
}

extension NoCodes.ActionType {
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

extension NoCodes.PresentationStyle {
    static func fromString(_ key: String?) -> NoCodes.PresentationStyle? {
        switch (key) {
        case "Push":
            return NoCodes.PresentationStyle.push
        case "FullScreen":
            return NoCodes.PresentationStyle.fullScreen
        case "Popover":
            return NoCodes.PresentationStyle.popover
        default:
            return nil
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func toPresentationConfig() -> NoCodes.PresentationConfiguration {
        guard let presentationStyleStr = self["presentationStyle"] as? String,
              let presentationStyle = NoCodes.PresentationStyle.fromString(presentationStyleStr)
        else { return NoCodes.PresentationConfiguration.defaultConfiguration() }

        let animated = (self["animated"] as? String)?.toBool() ?? true

        return NoCodes.PresentationConfiguration(animated: animated, presentationStyle: presentationStyle)
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
    
    if let nsError = error as? NSError, nsError.domain == QonversionErrorDomain || nsError.domain == QonversionApiErrorDomain {
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
