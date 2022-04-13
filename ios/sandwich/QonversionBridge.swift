//
//  QonversionBridge.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 12.04.2022.
//

import Foundation
import Qonversion

public class QonversionBridge : NSObject {
  
  private var qonversionEventListener: QonversionEventListener
  private var isSubscribedOnAsyncEvents: Bool = false
  private var promoPurchasesExecutionBlocks = [String: Qonversion.PromoPurchaseCompletionHandler]()

  public init(qonversionEventListener: QonversionEventListener) {
    self.qonversionEventListener = qonversionEventListener
  }
  
  public func launch(
    with projectKey: String,
    isObserveMode: Bool,
    completion: @escaping BridgeCompletion
  ) {
    Qonversion.launch(withKey: projectKey) { launchResult, error in
      if let nsError = error as NSError? {
        return completion(nil, nsError.toMap())
      }
      
      let resultDict = launchResult.toMap()
      return completion(resultDict, nil)
    }
    
    subscribeOnAsyncEvents()
  }
  
  public func identify(_ userId: String) {
    Qonversion.identify(userId)
  }
  
  public func storeSdkInfo(source: String, version: String) {
    let defaults = UserDefaults.standard
    defaults.set(source, forKey: UserDefaultsConstants.sourceKey)
    defaults.set(version, forKey: UserDefaultsConstants.sourceVersionKey)
  }
  
  public func products(completion: @escaping BridgeCompletion) {
    Qonversion.products { (products, error) in
      if let nsError = error as NSError? {
        return completion(nil, nsError.toMap())
      }
      
      let productsDict = products.mapValues { $0.toMap() }
      return completion(productsDict, nil)
    }
  }
  
  public func purchase(_ productId: String, completion: @escaping BridgeCompletion) {
    let purchaseCompletion = getPurchaseCompletionHandler(for: completion)
    Qonversion.purchase(productId, completion: purchaseCompletion)
  }
  
  public func purchaseProduct(_ productId: String, _ offeringId: String, completion: @escaping BridgeCompletion) {
    loadProduct(productId, offeringId) { (product) in
      guard let product = product else {
        return self.purchase(productId, completion: completion)
      }

      let purchaseCompletion = self.getPurchaseCompletionHandler(for: completion)
      Qonversion.purchaseProduct(product, completion: purchaseCompletion)
    }
  }
  
  public func promoPurchase(_ productId: String, completion: @escaping BridgeCompletion) {
    if let executionBlock = promoPurchasesExecutionBlocks[productId] {
      promoPurchasesExecutionBlocks.removeValue(forKey: productId)

      executionBlock { (permissions, error, isCancelled) in
        self.handlePurchaseResult(permissions, error, isCancelled, completion: completion)
      }
    } else {
      let error = NSError.init(domain: keyQNErrorDomain, code: Qonversion.Error.productNotFound.rawValue, userInfo: nil)
      completion(nil, error.toMap())
    }
  }
  
  public func checkPermissions(completion: @escaping BridgeCompletion) {
    Qonversion.checkPermissions { (permissions, error) in
      if let nsError = error as NSError? {
        return completion(nil, nsError.toMap())
      }
      
      let permissionsDict = permissions.mapValues { $0.toMap() }
      completion(permissionsDict, nil)
    }
  }
  
  public func restore(completion: @escaping BridgeCompletion) {
    Qonversion.restore { (permissions, error) in
      if let nsError = error as NSError? {
        return completion(nil, nsError.toMap())
      }
      
      let permissionsDict = permissions.mapValues { $0.toMap() }
      completion(permissionsDict, nil)
    }
  }
  
  public func offerings(completion: @escaping BridgeCompletion) {
    Qonversion.offerings { offerings, error in
      if let nsError = error as NSError? {
        completion(nil, nsError.toMap())
      }
      
      completion(offerings?.toMap(), nil)
    }
  }
  
  public func setDefinedProperty(property: String, value: String) {
    let parsedProperty = Qonversion.Property.fromString(property)

    guard let parsedProperty = parsedProperty else {
      return
    }

    Qonversion.setProperty(parsedProperty, value: value)
  }
  
  public func setCursomProperty(property: String, value: String) {
    Qonversion.setUserProperty(property, value: value)
  }
  
  public func checkTrialIntroEligibility(_ ids: [String], completion: @escaping BridgeCompletion) {
    Qonversion.checkTrialIntroEligibility(forProductIds: ids) { eligibilities, error in
      if let nsError = error as NSError? {
        return completion(nil, nsError.toMap())
      }
      
      let eligibilitiesDict = eligibilities.mapValues { $0.toMap() }
      completion(eligibilitiesDict, nil)
    }
  }

  public func addAttributionData(_ sourceKey: String, _ value: [String: Any]) {
    let provider = Qonversion.AttributionProvider.fromString(sourceKey)

    guard let provider = provider else {
      return
    }

    Qonversion.addAttributionData(value, from: provider)
  }
  
  public func setAppleSearchAdsAttributionEnabled(_ enable: Bool) {
    Qonversion.setAppleSearchAdsAttributionEnabled(enable)
  }
  
  public func setDebugMode() {
    Qonversion.setDebugMode()
  }
  
  public func logout() {
    Qonversion.logout()
  }
  
  public func setAdvertisingId() {
    Qonversion.setAdvertisingID()
  }
  
  public func presentCodeRedemptionSheet() {
    if #available(iOS 14.0, *) {
      Qonversion.presentCodeRedemptionSheet()
    }
  }
  
  public func experiments(completion: @escaping BridgeCompletion) {
    Qonversion.experiments() { experiments, error in
      if let nsError = error as NSError? {
        return completion(nil, nsError.toMap())
      }
      
      let experimentsDict = experiments.mapValues { $0.toMap() }
      completion(experimentsDict, nil)
    }
  }
  
  public func setNotificationToken(_ token: String) {
    let tokenData = token.toData()
    Qonversion.setNotificationsToken(tokenData)
  }
  
  public func handleNotification(_ notificationData: [AnyHashable: Any]) -> Bool {
    return Qonversion.handleNotification(notificationData)
  }
  
  typealias ProductCompletion = (_ result: Qonversion.Product?) -> Void
  
  private func loadProduct(_ productId: String, _ offeringId: String, completion: @escaping ProductCompletion) {
    Qonversion.offerings() { (offerings, error) in
      let offering = offerings?.offering(forIdentifier: offeringId);
      let product = offering?.product(forIdentifier: productId);
      return completion(product)
    }
  }
  
  private func getPurchaseCompletionHandler(for completion: @escaping BridgeCompletion) -> Qonversion.PurchaseCompletionHandler {
    return { (permissions, error, isCancelled) in
      self.handlePurchaseResult(permissions, error, isCancelled, completion: completion)
    }
  }
  
  private func handlePurchaseResult(
    _ permissions: [String: Qonversion.Permission],
    _ error: Error?,
    _ isCancelled: Bool,
    completion: @escaping BridgeCompletion
  ) {
    if let nsError = error as NSError? {
      var errorDict = nsError.toMap()
      errorDict["isCancelled"] = isCancelled
      return completion(nil, errorDict)
    }
    
    let permissionsDict = permissions.mapValues { $0.toMap() }
    completion(permissionsDict, nil)
  }
  
  private func subscribeOnAsyncEvents() {
    if (isSubscribedOnAsyncEvents) {
      return
    }
    
    Qonversion.setPurchasesDelegate(self)
    Qonversion.setPromoPurchasesDelegate(self)
    
    isSubscribedOnAsyncEvents = true
  }
}

extension QonversionBridge: Qonversion.PurchasesDelegate {
  public func qonversionDidReceiveUpdatedPermissions(_ permissions: [String : Qonversion.Permission]) {
    let permissionsDict = permissions.mapValues { $0.toMap() }
    
    qonversionEventListener.qonversionDidReceiveUpdatedPermissions(permissionsDict)
  }
}

extension QonversionBridge: QNPromoPurchasesDelegate {
  public func shouldPurchasePromoProduct(withIdentifier productID: String, executionBlock: @escaping Qonversion.PromoPurchaseCompletionHandler) {
    promoPurchasesExecutionBlocks[productID] = executionBlock
    
    qonversionEventListener.shouldPurchasePromoProduct(with: productID)
  }
}
