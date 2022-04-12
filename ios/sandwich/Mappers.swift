//
//  Mappers.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 11.04.2022.
//

import Foundation
import Qonversion

extension NSError {
  func toMap() -> [String: Any?] {
    let errorMap = [
      "code": code,
      "description": localizedDescription,
      "additionalMessage": userInfo[NSDebugDescriptionErrorKey]]
    
    return errorMap
  }
}

extension Qonversion.LaunchResult {
  func toMap() -> [String: Any] {
    return [
      "uid": uid,
      "timestamp": NSNumber(value: timestamp).intValue * 1000,
      "products": products.mapValues { $0.toMap() },
      "permissions": permissions.mapValues { $0.toMap() },
      "userProducts": userPoducts.mapValues { $0.toMap() },
    ]
  }
}

extension Qonversion.Product {
  func toMap() -> [String: Any?] {
    return [
        "id": qonversionID,
        "storeId": storeID,
        "type": type.rawValue,
        "duration": duration.rawValue,
        "skProduct": skProduct?.toMap(), // ??? sync name with android?
        "prettyPrice": prettyPrice,
        "trialDuration": trialDuration.rawValue,
        "offeringId": offeringID
    ]
  }
}



extension Qonversion.Permission {
  func toMap() -> [String: Any?] {
    return [
      "id": permissionID,
      "associatedProduct": productID,
      "renewState": renewState.rawValue,
      "startedTimestamp": startedDate.timeIntervalSince1970 * 1000,
      "expirationTimestamp": expirationDate?.timeIntervalSince1970 != nil ? expirationDate!.timeIntervalSince1970 * 1000 : nil,
      "active": isActive,
    ]
  }
}

extension Qonversion.Offerings {
  func toMap() -> [String: Any?] {
    return [
      "main": main?.toMap(),
      "availableOfferings": availableOfferings.map { $0.toMap() }
    ]
  }
}

extension Qonversion.Offering {
  func toMap() -> [String: Any?] {
    return [
      "id": identifier,
      "tag": tag.rawValue,
      "products": products.map { $0.toMap() }
    ]
  }
}

extension Qonversion.IntroEligibility {
  func toMap() -> [String: Any?] {
    return ["status": status.rawValue]
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
      return .adjustUserID
      
    case "KochavaDeviceId":
      return .kochavaDeviceID
      
    case "CustomUserId":
      return .userID
      
    default:
      return nil
    }
  }
}

extension Qonversion.ActionResult {
  func toMap() -> [String: Any?] {
    let nsError = error as NSError?
    
    return ["type": type.rawValue,
            "value": parameters,
            "error": nsError?.toMap()]
  }
}

extension QONAutomationsEvent {
  func toMap() -> [String: Any?] {
    return ["type": type.rawValue,
            "timestamp": date.toMilliseconds()]
  }
}

extension SKProduct {
  func toMap() -> [String: Any?] {
    var map: [String: Any?] = [
      "localizedDescription": localizedDescription,
      "localizedTitle": localizedTitle,
      "productIdentifier": productIdentifier,
      "price": price.description,
      "priceLocale": priceLocale.toMap(),
      "isDownloadable": isDownloadable,
      "downloadContentVersion": downloadContentVersion,
      "downloadContentLengths": downloadContentLengths
    ]
    
    if #available(iOS 11.2, macOS 10.13.2, *) {
      map["subscriptionPeriod"] = subscriptionPeriod?.toMap()
      map["introductoryPrice"] = introductoryPrice?.toMap()
      map["discounts"] = discounts.map { $0.toMap() }
    }

    if #available(iOS 12.0, macOS 10.14, *) {
      map["subscriptionGroupIdentifier"] = subscriptionGroupIdentifier
    }
      
    if #available(iOS 14.0, *) {
      map["isFamilyShareable"] = isFamilyShareable;
    }
    
    return map
  }
}

extension Locale {
  func toMap() -> [String: Any?] {
    return [
      "currencySymbol": currencySymbol,
      "currencyCode": currencyCode,
      "localeIdentifier": identifier
    ]
  }
}

@available(iOS 11.2, macOS 10.13.2, *)
extension SKProductSubscriptionPeriod {
  func toMap() -> [String: Any] {
    return [
      "numberOfUnits": numberOfUnits,
      "unit": unit.rawValue
    ]
  }
}

@available(iOS 11.2, macOS 10.13.2, *)
extension SKProductDiscount {
  func toMap() -> [String: Any] {
    var map: [String: Any] = [
      "price": price.description,
      "numberOfPeriods": numberOfPeriods,
      "subscriptionPeriod": subscriptionPeriod.toMap(),
      "paymentMode": paymentMode.rawValue,
      "priceLocale": priceLocale.toMap()
    ]
      
    if #available(iOS 12.0, *) {
      map["identifier"] = identifier
      map["type"] = type
    }
      
    return map
  }
}

extension Qonversion.ExperimentInfo {
  func toMap() -> [String: Any?] {
    return [
      "id": identifier,
      "group": [
        "type": group?.type
      ]
    ]
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
}
