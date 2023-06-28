//
//  Mappers.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 11.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation
import Qonversion

extension BridgeData {
    func clearEmptyValues() -> [String: Any] {
        func clear(_ value: Any?) -> Any? {
            if let value = value as? [Any?] {
                return value.compactMap {
                    clear($0)
                }
            } else if let value = value as? [String: Any?] {
                return value.compactMapValues {
                    clear($0)
                }
            } else {
                return value
            }
        }
        
        return compactMapValues {
            clear($0)
        }
    }
}

extension NSError {
  func toSandwichError() -> SandwichError {
    return SandwichError(
      code: String(code),
      domain: domain,
      details: localizedDescription,
      additionalMessage: userInfo[NSDebugDescriptionErrorKey] as? String
    )
  }
  
  func toMap() -> BridgeData {
    let errorMap = [
      "code": String(code),
      "domain": domain,
      "description": localizedDescription,
      "additionalMessage": userInfo[NSDebugDescriptionErrorKey]]
    
    return errorMap
  }
}

extension Qonversion.Product {
  func toMap() -> BridgeData {
    return [
        "id": qonversionID,
        "storeId": storeID,
        "type": type.rawValue,
        "duration": duration.rawValue,
        "skProduct": skProduct?.toMap(),
        "prettyPrice": prettyPrice,
        "trialDuration": trialDuration.rawValue,
        "offeringId": offeringID
    ]
  }
}

extension Qonversion.Entitlement {
  func toMap() -> BridgeData {
    return [
      "id": entitlementID,
      "productId": productID,
      "renewState": renewState.toString(),
      "startedTimestamp": startedDate.toMilliseconds(),
      "expirationTimestamp": expirationDate.map { $0.toMilliseconds() },
      "active": isActive,
      "source": source.toString(),
    ]
  }
}

extension Qonversion.User {
  func toMap() -> BridgeData {
    return [
      "qonversionId": qonversionId,
      "identityId": identityId,
      "originalAppVersion": originalAppVersion,
    ]
  }
}

extension Qonversion.Offerings {
  func toMap() -> BridgeData {
    return [
      "main": main?.toMap(),
      "availableOfferings": availableOfferings.map { $0.toMap() }
    ]
  }
}

extension Qonversion.Offering {
  func toMap() -> BridgeData {
    return [
      "id": identifier,
      "tag": tag.rawValue,
      "products": products.map { $0.toMap() }
    ]
  }
}

extension Qonversion.IntroEligibility {
  func toMap() -> BridgeData {
    let statusValue: String
    
    switch status {
    case .eligible: statusValue = "intro_or_trial_eligible"
    case .ineligible: statusValue = "intro_or_trial_ineligible"
    case .nonIntroProduct: statusValue = "non_intro_or_trial_product"
    default: statusValue = "unknown"
    }
    
    return ["status": statusValue]
  }
}

extension Qonversion.LaunchMode {
  static func fromString(_ string: String) -> Self? {
    switch string {
    case "Analytics":
      return .analytics

    case "SubscriptionManagement":
      return .subscriptionManagement
      
    default:
      return nil
    }
  }
}

extension Qonversion.EntitlementSource {
  func toString() -> String {
    switch self {
    case .unknown:
      return "Unknown"
    case .appStore:
      return "AppStore"
    case .playStore:
      return "PlayStore"
    case .stripe:
      return "Stripe"
    case .manual:
      return "Manual"
    default:
      return "Unknown"
    }
  }
}

extension Qonversion.EntitlementRenewState {
  func toString() -> String {
    switch self {
    case .nonRenewable:
      return "non_renewable"
    case .willRenew:
      return "will_renew"
    case .cancelled:
      return "canceled"
    case .billingIssue:
      return "billing_issue"
    default:
      return "unknown"
    }
  }
}

extension Qonversion.Property {
  static func fromString(_ string: String) -> Self? {
    switch string {
    case "Email":
      return .email

    case "Name":
      return .name

    case "AppsFlyerUserId":
      return .appsFlyerUserID

    case "AdjustAdId":
      return .adjustAdID
      
    case "KochavaDeviceId":
      return .kochavaDeviceID
      
    case "CustomUserId":
      return .userID
      
    case "AdvertisingId":
      return .advertisingID
      
    case "FirebaseAppInstanceId":
      return .firebaseAppInstanceId
      
    default:
      return nil
    }
  }
}

extension Qonversion.Environment {
  static func fromString(_ string: String?) -> Self? {
    switch string {
    case "Production":
      return .production
    case "Sandbox":
      return .sandbox
    default:
      return nil
    }
  }
}

extension Qonversion.EntitlementsCacheLifetime {
  static func fromString(_ string: String?) -> Self? {
    switch string {
    case "Week":
      return .week

    case "TwoWeeks":
      return .twoWeeks

    case "Month":
      return .month

    case "TwoMonths":
      return .twoMonths

    case "ThreeMonths":
      return .threeMonths

    case "SixMonths":
      return .sixMonths

    case "Year":
      return .year

    case "Unlimited":
      return .unlimited

    default:
      return nil
    }
  }
}

extension Qonversion.AttributionProvider {
  static func fromString(_ string: String) -> Self? {
    switch string {
    case "AppsFlyer":
      return .appsFlyer
    case "Branch":
      return .branch
    case "Adjust":
      return .adjust
    case "AppleSearchAds":
      return .appleSearchAds
    case "AppleAdServices":
      return .appleAdServices
    default:
      return nil
    }
  }
}

extension SKProduct {
  func toMap() -> BridgeData {
    var map: BridgeData = [
      "localizedDescription": localizedDescription,
      "localizedTitle": localizedTitle,
      "productIdentifier": productIdentifier,
      "price": price.stringValue,
      "priceLocale": priceLocale.toMap()
    ]
    
    if #available(iOS 6.0, macOS 10.14, watchOS 6.2, *) {
      map["downloadContentVersion"] = downloadContentVersion
      map["downloadContentLengths"] = downloadContentLengths
    }
    
    if #available(iOS 6.0, macOS 10.15, watchOS 6.2, *) {
      map["isDownloadable"] = isDownloadable
    }
    
    if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, watchOS 6.2, *) {
      map["subscriptionPeriod"] = subscriptionPeriod?.toMap()
      map["introductoryPrice"] = introductoryPrice?.toMap()
    }
    
    if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
      map["discounts"] = discounts.map { $0.toMap() }
    }

    if #available(iOS 12.0, tvOS 12.0, macOS 10.14, *) {
      map["subscriptionGroupIdentifier"] = subscriptionGroupIdentifier
    }
      
    if #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *) {
      map["isFamilyShareable"] = isFamilyShareable
    }
    
    return map
  }
}

extension Locale {
  func toMap() -> BridgeData {
    return [
      "currencySymbol": currencySymbol,
      "currencyCode": currencyCode,
      "localeIdentifier": identifier
    ]
  }
}

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
extension SKProductSubscriptionPeriod {
  func toMap() -> BridgeData {
    return [
      "numberOfUnits": numberOfUnits,
      "unit": unit.rawValue
    ]
  }
}

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)
extension SKProductDiscount {
  func toMap() -> BridgeData {
    var map: BridgeData = [
      "price": price.stringValue,
      "numberOfPeriods": numberOfPeriods,
      "subscriptionPeriod": subscriptionPeriod.toMap(),
      "paymentMode": paymentMode.rawValue,
      "priceLocale": priceLocale.toMap()
    ]
      
    if #available(iOS 12.2, tvOS 12.2, watchOS 6.2, macOS 10.14.4, *) {
      map["type"] = type.rawValue
      map["identifier"] = identifier
    }
    
    return map
  }
}

extension Qonversion.RemoteConfig {
  func toMap() -> BridgeData {
    return [
      "payload": payload,
      "experiment": experiment?.toMap()
    ]
  }
}

extension Qonversion.Experiment {
  func toMap() -> BridgeData {
    return [
      "id": identifier,
      "name": name,
      "group": group.toMap()
    ]
  }
}

extension Qonversion.ExperimentGroup {
  func toMap() -> BridgeData {
    return [
        "id": identifier,
        "name": name,
        "type": type.toString()
    ]
  }
}

extension Qonversion.ExperimentGroupType {
  func toString() -> String {
    switch self {
    case .treatment:
      return "treatment"
    case .control:
      return "control"
    default:
      return "unknown"
    }
  }
}

extension Date {
    func toMilliseconds() -> Double {
      return timeIntervalSince1970 * 1000
    }
}

extension String {
  func toData() -> Data {
    let len = count / 2
    var data = Data(capacity: len)
    var i = startIndex
    for _ in 0..<len {
      let j = index(i, offsetBy: 2)
      let bytes = self[i..<j]
      if var num = UInt8(bytes, radix: 16) {
        data.append(&num, count: 1)
      }
      i = j
    }
    
    return data
  }

  func toBool() -> Bool {
    return self == "true" || (Int(self) ?? 0) != 0
  }
}

#if os(iOS)
extension Qonversion.ScreenPresentationStyle {
  static func fromString(_ key: String?) -> Qonversion.ScreenPresentationStyle? {
    switch (key) {
    case "Push":
      return Qonversion.ScreenPresentationStyle.push
    case "FullScreen":
      return Qonversion.ScreenPresentationStyle.fullScreen
    case "Popover":
      return Qonversion.ScreenPresentationStyle.popover
    default:
      return nil
    }
  }
}

extension Dictionary where Key == String, Value == Any  {
  func toScreenPresentationConfig() -> Qonversion.ScreenPresentationConfiguration {
    guard let presentationStyleStr = self["presentationStyle"] as? String,
          let presentationStyle = Qonversion.ScreenPresentationStyle.fromString(presentationStyleStr)
    else { return Qonversion.ScreenPresentationConfiguration.default() }

    let animated = (self["animated"] as? String)?.toBool() ?? true

    return Qonversion.ScreenPresentationConfiguration(presentationStyle: presentationStyle, animated: animated)
  }
}
#endif
