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
  func stringCode() -> String {
      let codes = [
        Qonversion.ErrorCode.unknown.rawValue: "Unknown",
        Qonversion.ErrorCode.purchaseCanceled.rawValue: "PurchaseCanceled",
        Qonversion.ErrorCode.productNotFound.rawValue: "ProductNotFound",
        Qonversion.ErrorCode.clientInvalid.rawValue: "ClientInvalid",
        Qonversion.ErrorCode.paymentInvalid.rawValue: "PaymentInvalid",
        Qonversion.ErrorCode.paymentNotAllowed.rawValue: "PaymentNotAllowed",
        Qonversion.ErrorCode.storeProductNotAvailable.rawValue: "StoreProductNotAvailable",
        Qonversion.ErrorCode.cloudServicePermissionDenied.rawValue: "CloudServicePermissionDenied",
        Qonversion.ErrorCode.cloudServiceNetworkConnectionFailed.rawValue: "CloudServiceNetworkConnectionFailed",
        Qonversion.ErrorCode.cloudServiceRevoked.rawValue: "CloudServiceRevoked",
        Qonversion.ErrorCode.privacyAcknowledgementRequired.rawValue: "PrivacyAcknowledgementRequired",
        Qonversion.ErrorCode.unauthorizedRequestData.rawValue: "UnauthorizedRequestData",
        Qonversion.ErrorCode.networkConnectionFailed.rawValue: "NetworkConnectionFailed",
        Qonversion.ErrorCode.internalError.rawValue: "InternalError",
        Qonversion.ErrorCode.purchasePending.rawValue: "PurchasePending",
        Qonversion.ErrorCode.remoteConfigurationNotAvailable.rawValue: "RemoteConfigurationNotAvailable",
        Qonversion.ErrorCode.failedToReceiveData.rawValue: "FailedToReceiveData",
        Qonversion.ErrorCode.responseParsingFailed.rawValue: "ResponseParsingFailed",
        Qonversion.ErrorCode.incorrectRequest.rawValue: "IncorrectRequest",
        Qonversion.ErrorCode.backendError.rawValue: "BackendError",
        Qonversion.ErrorCode.invalidCredentials.rawValue: "InvalidCredentials",
        Qonversion.ErrorCode.invalidClientUID.rawValue: "InvalidClientUid",
        Qonversion.ErrorCode.unknownClientPlatform.rawValue: "UnknownClientPlatform",
        Qonversion.ErrorCode.fraudPurchase.rawValue: "FraudPurchase",
        Qonversion.ErrorCode.featureNotSupported.rawValue: "FeatureNotSupported",
        Qonversion.ErrorCode.appleStoreError.rawValue: "AppleStoreError",
        Qonversion.ErrorCode.purchaseInvalid.rawValue: "PurchaseInvalid",
        Qonversion.ErrorCode.projectConfigError.rawValue: "ProjectConfigError",
        Qonversion.ErrorCode.invalidStoreCredentials.rawValue: "InvalidStoreCredentials",
        Qonversion.ErrorCode.receiptValidationError.rawValue: "ReceiptValidationError",
        Qonversion.ErrorCode.apiRateLimitExceeded.rawValue: "ApiRateLimitExceeded",
        Qonversion.ErrorCode.offeringsNotAvailable.rawValue: "OfferingsNotAvailable",
      ]

      var strCode = codes[code]

      if (strCode == nil && domain == NSURLErrorDomain) {
        strCode = codes[Qonversion.ErrorCode.networkConnectionFailed.rawValue]
      }

      if (strCode == nil && domain == QonversionErrorDomain) {
        let authErrorCodes = QNUtils.authErrorsCodes() as? [NSNumber] ?? []

        if (code >= 500 && code < 600) {
          strCode = codes[Qonversion.ErrorCode.internalError.rawValue]
        } else if (authErrorCodes.contains { $0.intValue == code }) {
          strCode = codes[Qonversion.ErrorCode.invalidCredentials.rawValue]
        }
      }
    
      return strCode ?? "Unknown"
  }
  
  func toSandwichError() -> SandwichError {

    return SandwichError(
      code: stringCode(),
      domain: domain,
      details: localizedDescription,
      additionalMessage: userInfo[NSDebugDescriptionErrorKey] as? String
    )
  }
  
  func toMap() -> BridgeData {
    return [
      "code": stringCode(),
      "domain": domain,
      "description": localizedDescription,
      "additionalMessage": "Original code: " + String(code) + ". " + (userInfo[NSDebugDescriptionErrorKey] as? String ?? "")
    ]
  }
}

extension Qonversion.Product {
  func toMap() -> BridgeData {
    var subscriptionPeriodMap: BridgeData? = nil
    var trialPeriodMap: BridgeData? = nil
    if #available(iOS 11.2, macOS 10.13.2, watchOS 6.2, tvOS 11.2, *) {
        subscriptionPeriodMap = subscriptionPeriod?.toMap()
        trialPeriodMap = trialPeriod?.toMap()
    }

    return [
      "id": qonversionID,
      "storeId": storeID,
      "type": type.toString(),
      "subscriptionPeriod": subscriptionPeriodMap,
      "skProduct": skProduct?.toMap(),
      "prettyPrice": prettyPrice,
      "trialPeriod": trialPeriodMap,
      "offeringId": offeringID
    ]
  }
}

@available(iOS 11.2, macOS 10.13.2, watchOS 6.2, tvOS 11.2, *)
extension Qonversion.SubscriptionPeriod {
  func toMap() -> BridgeData {
    let unitStr = unit.toString()
    let firstLetter = unitStr.prefix(1)

    return [
      "unit": unitStr,
      "unitCount": unitCount,
      "iso": "P\(unitCount)\(firstLetter)"
    ]
  }
}

@available(iOS 12.2, macOS 10.14.4, watchOS 6.2, tvOS 12.2, visionOS 1.0, *)
extension Qonversion.PromotionalOffer {
  func toMap() -> BridgeData {
    return ["productDiscount": productDiscount.toMap(),
            "paymentDiscount": paymentDiscount.toMap()]
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
      "renewsCount": renewsCount,
      "trialStartTimestamp": trialStartDate.map { $0.toMilliseconds() },
      "firstPurchaseTimestamp": firstPurchaseDate.map { $0.toMilliseconds() },
      "lastPurchaseTimestamp": lastPurchaseDate.map { $0.toMilliseconds() },
      "lastActivatedOfferCode": lastActivatedOfferCode,
      "grantType": grantType.toString(),
      "autoRenewDisableTimestamp": autoRenewDisableDate.map { $0.toMilliseconds() },
      "transactions": transactions.map { $0.toMap() }
    ]
  }
}

extension Qonversion.EntitlementGrantType {
  func toString() -> String {
    switch self {
    case .purchase:
      return "Purchase"
    case .familySharing:
      return "FamilySharing"
    case .offerCode:
      return "OfferCode"
    case .manual:
      return "Manual"
    default:
        return "Unknown"
    }
  }
}

extension Qonversion.Transaction {
  func toMap() -> BridgeData {
    return [
      "originalTransactionId": originalTransactionId,
      "transactionId": transactionId,
      "offerCode": offerCode,
      "transactionTimestamp": transactionDate.toMilliseconds(),
      "expirationTimestamp": expirationDate.map { $0.toMilliseconds() },
      "transactionRevocationTimestamp": transactionRevocationDate.map { $0.toMilliseconds() },
      "environment": environment.toString(),
      "ownershipType": ownershipType.toString(),
      "type": type.toString(),
      "promoOfferId": promoOfferId
    ]
  }
}

extension Qonversion.TransactionEnvironment {
  func toString() -> String {
    switch self {
    case .sandbox:
      return "Sandbox"
    case .production:
      return "Production"
    default:
      return "Production"
    }
  }
}

extension Qonversion.TransactionOwnershipType {
  func toString() -> String {
    switch self {
    case .owner:
      return "Owner"
    case .familySharing:
      return "FamilySharing"
    default:
      return "Owner"
    }
  }
}

extension Qonversion.TransactionType {
  func toString() -> String {
    switch self {
    case .subscriptionStarted:
      return "SubscriptionStarted"
    case .subscriptionRenewed:
      return "SubscriptionRenewed"
    case .trialStarted:
      return "TrialStarted"
    case .introStarted:
      return "IntroStarted"
    case .introRenewed:
      return "IntroRenewed"
    case .nonConsumablePurchase:
      return "NonConsumablePurchase"
    default:
      return "Unknown"
    }
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
    case .nonIntroOrTrialProduct: statusValue = "non_intro_or_trial_product"
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

extension Qonversion.SubscriptionPeriodUnit {
  func toString() -> String {
    switch self {
    case .day:
      return "Day"
    case .week:
      return "Week"
    case .month:
      return "Month"
    case .year:
      return "Year"
    @unknown default:
      return "Unknown"
    }
  }
}

extension Qonversion.ProductType {
  func toString() -> String {
    switch self {
    case .unknown:
      return "Unknown"
    case .trial:
      return "Trial"
    case .directSubscription:
      return "Subscription"
    case .oneTime:
      return "InApp"
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

extension Qonversion.UserPropertyKey {
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
      
    case "FacebookAttribution":
      return .facebookAttribution
      
    case "AppSetId":
      return .appSetId
      
    case "AppMetricaDeviceId":
      return .appMetricaDeviceId
      
    case "AppMetricaUserProfileId":
      return .appMetricaUserProfileId
      
    case "PushWooshHwId":
      return .pushWooshHwId
      
    case "PushWooshUserId":
      return .pushWooshUserId
      
    case "TenjinAnalyticsInstallationId":
      return .tenjinAnalyticsInstallationId

    default:
      return nil
    }
  }
}

extension Qonversion.UserProperties {
  func toMap() -> BridgeData {
    let propertiesArray: [BridgeData] = properties.map { userProperty in
      userProperty.toMap()
    }

    return [
      "properties": propertiesArray,
    ];
  }
}

extension Qonversion.UserProperty {
  func toMap() -> BridgeData {
    return [
      "key": key,
      "value": value,
    ];
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

@available(iOS 12.2, macOS 10.14.4, watchOS 6.2, tvOS 12.2, visionOS 1.0, *)
extension SKPaymentDiscount {
  func toMap() -> BridgeData {
    return ["identifier": identifier,
            "nonce": nonce.uuidString,
            "signature": signature,
            "keyIdentifier": keyIdentifier,
            "timestamp": timestamp]
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

extension Qonversion.RemoteConfigList {
  func toMap() -> BridgeData {
    return [
      "remoteConfigs": remoteConfigs.map { $0.toMap() }
    ]
  }
}

extension Qonversion.RemoteConfig {
  func toMap() -> BridgeData {
    return [
      "payload": payload,
      "experiment": experiment?.toMap(),
      "source": source.toMap()
    ]
  }
}

extension Qonversion.RemoteConfigurationSource {
  func toMap() -> BridgeData {
    return [
      "id": identifier,
      "name": name,
      "type": type.toString(),
      "assignmentType": assignmentType.toString(),
      "contextKey": contextKey
    ]
  }
}

extension Qonversion.RemoteConfigurationSourceType {
  func toString() -> String {
    switch self {
    case .experimentControlGroup:
      return "experiment_control_group"
    case .experimentTreatmentGroup:
      return "experiment_treatment_group"
    case .remoteConfiguration:
      return "remote_configuration"
    default:
      return "unknown"
    }
  }
}

extension Qonversion.RemoteConfigurationAssignmentType {
  func toString() -> String {
    switch self {
    case .auto:
      return "auto"
    case .manual:
      return "manual"
    default:
      return "unknown"
    }
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

// MARK: - PurchaseResult Mappers

extension Qonversion.PurchaseResult {
  func toMap() -> BridgeData {
    return [
      "status": status.toString(),
      "entitlements": entitlements?.mapValues { $0.toMap() },
      "error": (error as NSError?)?.toMap(),
      "isFallbackGenerated": isFallbackGenerated,
      "source": source.toString(),
      "storeTransaction": transaction?.toStoreTransactionMap()
    ]
  }
}

extension Qonversion.PurchaseResultStatus {
  func toString() -> String {
    switch self {
    case .success:
      return "Success"
    case .userCanceled:
      return "UserCanceled"
    case .pending:
      return "Pending"
    case .error:
      return "Error"
    @unknown default:
      return "Error"
    }
  }
}

extension Qonversion.PurchaseResultSource {
  func toString() -> String {
    switch self {
    case .api:
      return "Api"
    case .local:
      return "Local"
    @unknown default:
      return "Api"
    }
  }
}

// MARK: - StoreTransaction Mapper

extension SKPaymentTransaction {
  func toStoreTransactionMap() -> BridgeData {
    var promoOfferId: String? = nil
    if #available(iOS 12.2, macOS 10.14.4, watchOS 6.2, tvOS 12.2, visionOS 1.0, *) {
      promoOfferId = payment.paymentDiscount?.identifier
    }
    
    return [
      "transactionId": transactionIdentifier,
      "originalTransactionId": originalTransaction?.transactionIdentifier ?? transactionIdentifier,
      "transactionTimestamp": transactionDate?.toMilliseconds(),
      "productId": payment.productIdentifier,
      "quantity": payment.quantity,
      "promoOfferId": promoOfferId,
      "purchaseToken": nil // iOS doesn't have purchaseToken, only Android
    ]
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
