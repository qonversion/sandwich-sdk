//
//  Mappers.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 11.04.2022.
//

import Foundation

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
      "user_products": userPoducts.mapValues { $0.toMap() },
    ]
  }
}

extension Qonversion.Product {
  func toMap() -> [String: Any?] {
    return [
        "id": qonversionID,
        "store_id": storeID,
        "type": type.rawValue,
        "duration": duration.rawValue,
        "sk_product": skProduct?.toMap(), // ??? sync name with android?
        "pretty_price": prettyPrice,
        "trial_duration": trialDuration.rawValue,
        "offering_id": offeringID
    ]
  }
}



extension Qonversion.Permission {
  func toMap() -> [String: Any?] {
    return [
      "id": permissionID,
      "associated_product": productID,
      "renew_state": renewState.rawValue,
      "started_timestamp": startedDate.timeIntervalSince1970 * 1000,
      "expiration_timestamp": expirationDate?.timeIntervalSince1970 != nil ? expirationDate!.timeIntervalSince1970 * 1000 : nil,
      "active": isActive,
    ]
  }
}

extension Qonversion.Offerings {
  func toMap() -> [String: Any?] {
    return [
      "main": main?.toMap(),
      "available_offerings": availableOfferings.map { $0.toMap() }
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
  static func fromString(_ string: String) throws -> Self {
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
      throw ParsingError.runtimeError("Could not parse Qonversion.Property")
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
