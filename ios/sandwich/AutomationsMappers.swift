//
//  AutomationsMappers.swift
//  QonversionSandwich
//
//  Created by Suren Sarkisyan on 20.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation
import Qonversion

extension Qonversion.ActionResultType {
  func toString() -> String {
    switch self {
    case .URL: return "url"
    case .deeplink: return "deeplink"
    case .navigation: return "navigate"
    case .purchase: return "purchase"
    case .restore: return "restore"
    case .close: return "close"
    default: return "unknown"
    }
  }
}

extension Qonversion.ActionResult {
  func toMap() -> BridgeData {
    let nsError = error as NSError?
    
    return ["type": type.toString(),
            "value": parameters,
            "error": nsError?.toMap()]
  }
}

extension Qonversion.AutomationsEventType {
  func toString() -> String {
    switch self {
    case .trialStarted: return "trial_started"
    case .trialConverted: return "trial_converted"
    case .trialCanceled: return "trial_canceled"
    case .trialBillingRetry: return "trial_billing_retry_entered"
    case .subscriptionStarted: return "subscription_started"
    case .subscriptionRenewed: return "subscription_renewed"
    case .subscriptionRefunded: return "subscription_refunded"
    case .subscriptionCanceled: return "subscription_canceled"
    case .subscriptionBillingRetry: return "subscription_billing_retry_entered"
    case .inAppPurchase: return "in_app_purchase"
    case .subscriptionUpgraded: return "subscription_upgraded"
    case .trialStillActive: return "trial_still_active"
    case .trialExpired: return "trial_expired"
    case .subscriptionExpired: return "subscription_expired"
    case .subscriptionDowngraded: return "subscription_downgraded"
    case .subscriptionProductChanged: return "subscription_product_changed"
    default: return "unknown"
    }
  }
}

extension QONAutomationsEvent {
  func toMap() -> BridgeData {
    return ["type": type.toString(),
            "timestamp": date.toMilliseconds()]
  }
}
