import Foundation
#if os(iOS)
import NoCodes

extension NoCodes.Action {
    func toMap() -> BridgeData {
        return [
            "type": type.toString(),
            "value": parameters
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
    func toNoCodesPresentationConfig() -> NoCodes.PresentationConfiguration {
        guard let presentationStyleStr = self["presentationStyle"] as? String,
              let presentationStyle = NoCodes.PresentationStyle.fromString(presentationStyleStr)
        else { return NoCodes.PresentationConfiguration.defaultConfiguration() }

        let animated = (self["animated"] as? String)?.toBool() ?? true

        return NoCodes.PresentationConfiguration(animated: animated, presentationStyle: presentationStyle)
    }
}
#endif 
