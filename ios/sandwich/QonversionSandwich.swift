//
//  QonversionSandwich.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 12.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation
import Qonversion

public class QonversionSandwich : NSObject {
  
  // MARK: - Private variables
  
  private var qonversionEventListener: QonversionEventListener? = nil
  private var isSubscribedOnAsyncEvents: Bool = false
  private var promoPurchasesExecutionBlocks = [String: Qonversion.PromoPurchaseCompletionHandler]()
  
  // MARK: - Public Functions
  
  // MARK: Initialization
  
  @objc public init(qonversionEventListener: QonversionEventListener) {
    self.qonversionEventListener = qonversionEventListener
  }
  
  @objc public func launch(
    projectKey: String,
    completion: @escaping BridgeCompletion
  ) {
    Qonversion.launch(withKey: projectKey) { launchResult, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let bridgeData: [String: Any] = launchResult.toMap().clearEmptyValues()
      
      completion(bridgeData, nil)
    }
    
    subscribeOnAsyncEvents()
  }
  
  @objc public func storeSdkInfo(source: String, version: String) {
    let defaults = UserDefaults.standard
    defaults.set(source, forKey: UserDefaultsConstants.sourceKey)
    defaults.set(version, forKey: UserDefaultsConstants.sourceVersionKey)
  }
  
  @objc public func setDebugMode() {
    Qonversion.setDebugMode()
  }
  
  // MARK: Product Center
  
  @objc public func purchase(_ productId: String, completion: @escaping BridgeCompletion) {
    let purchaseCompletion = getPurchaseCompletionHandler(for: completion)
    Qonversion.purchase(productId, completion: purchaseCompletion)
  }
  
  @objc public func purchaseProduct(_ productId: String, _ offeringId: String, completion: @escaping BridgeCompletion) {
    loadProduct(productId, offeringId) { [weak self] (product) in
      guard let self = self else { return }
      
      guard let product = product else {
        return self.purchase(productId, completion: completion)
      }

      let purchaseCompletion = self.getPurchaseCompletionHandler(for: completion)
      Qonversion.purchaseProduct(product, completion: purchaseCompletion)
    }
  }
  
  @objc public func promoPurchase(_ productId: String, completion: @escaping BridgeCompletion) {
    if let executionBlock = promoPurchasesExecutionBlocks[productId] {
      promoPurchasesExecutionBlocks[productId] = nil

      executionBlock { [weak self] (permissions, error, isCancelled) in
        self?.handlePurchaseResult(permissions, error, isCancelled, completion: completion)
      }
    } else {
      let error = NSError.init(domain: keyQNErrorDomain, code: Qonversion.Error.productNotFound.rawValue, userInfo: nil)
      
      completion(nil, error.toSandwichError())
    }
  }
  
  @objc public func checkPermissions(_ completion: @escaping BridgeCompletion) {
    Qonversion.checkPermissions { (permissions, error) in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let permissionsDict: [String: Any] = permissions.mapValues { $0.toMap() }.clearEmptyValues()
      
      completion(permissionsDict, nil)
    }
  }
  
  @objc public func offerings(_ completion: @escaping BridgeCompletion) {
    Qonversion.offerings { offerings, error in
      if let error = error as NSError? {
        completion(nil, error.toSandwichError())
      }
      
      let bridgeData: [String: Any]? = offerings?.toMap().clearEmptyValues()
      
      completion(bridgeData, nil)
    }
  }
  
  @objc public func products(_ completion: @escaping BridgeCompletion) {
    Qonversion.products { (products, error) in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let productsDict: [String: Any] = products.mapValues { $0.toMap() }.clearEmptyValues()
      
      completion(productsDict, nil)
    }
  }
  
  @objc public func restore(_ completion: @escaping BridgeCompletion) {
    Qonversion.restore { (permissions, error) in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let permissionsDict: [String: Any] = permissions.mapValues { $0.toMap() }.clearEmptyValues()
      
      completion(permissionsDict, nil)
    }
  }
  
  @objc public func checkTrialIntroEligibility(_ ids: [String], completion: @escaping BridgeCompletion) {
    Qonversion.checkTrialIntroEligibility(forProductIds: ids) { eligibilities, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      var eligibilitiesDict: [String: [String: Any]] = [:]
      eligibilities.forEach { (key, value) in
        eligibilitiesDict[key] = value.toMap().clearEmptyValues()
      }
      
      completion(eligibilitiesDict, nil)
    }
  }
  
  @objc public func experiments(_ completion: @escaping BridgeCompletion) {
    Qonversion.experiments() { experiments, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let experimentsDict: [String: Any] = experiments.mapValues { $0.toMap() }.clearEmptyValues()
      
      completion(experimentsDict, nil)
    }
  }
  
#if os(iOS)
  @available (iOS 14.0, *)
  @objc public func presentCodeRedemptionSheet() {
    Qonversion.presentCodeRedemptionSheet()
  }
#endif
  
  // MARK: User Info
  
  @objc public func identify(_ userId: String) {
    Qonversion.identify(userId)
  }
  
  @objc public func setDefinedProperty(_ property: String, value: String) {
    guard let parsedProperty = Qonversion.Property.fromString(property) else { return }

    Qonversion.setProperty(parsedProperty, value: value)
  }
  
  @objc public func setCustomProperty(_ property: String, value: String) {
    Qonversion.setUserProperty(property, value: value)
  }
  
  @objc public func logout() {
    Qonversion.logout()
  }

  @objc public func addAttributionData(sourceKey: String, value: [String: Any]) {
    guard let provider = Qonversion.AttributionProvider.fromString(sourceKey) else { return}

    Qonversion.addAttributionData(value, from: provider)
  }
  
  @objc public func setAppleSearchAdsAttributionEnabled(_ enable: Bool) {
    Qonversion.setAppleSearchAdsAttributionEnabled(enable)
  }
  
  @objc public func setAdvertisingId() {
    Qonversion.setAdvertisingID()
  }
  
  // MARK: Notifications
  
  @objc public func setNotificationToken(_ token: String) {
    let tokenData: Data = token.toData()
    Qonversion.setNotificationsToken(tokenData)
  }
  
#if os(iOS)
  @objc public func handleNotification(_ notificationData: [AnyHashable: Any]) -> Bool {
    return Qonversion.handleNotification(notificationData)
  }
#endif
  
  // MARK: - Private functions
  
  private func loadProduct(_ productId: String, _ offeringId: String, completion: @escaping ProductCompletion) {
    Qonversion.offerings() { (offerings, error) in
      let offering: Qonversion.Offering? = offerings?.offering(forIdentifier: offeringId);
      let product: Qonversion.Product? = offering?.product(forIdentifier: productId);
     
      completion(product)
    }
  }
  
  private func getPurchaseCompletionHandler(for completion: @escaping BridgeCompletion) -> Qonversion.PurchaseCompletionHandler {
    let purchaseCompletion: Qonversion.PurchaseCompletionHandler = { [weak self] (permissions, error, isCancelled) in
      self?.handlePurchaseResult(permissions, error, isCancelled, completion: completion)
    }
    
    return purchaseCompletion
  }
  
  private func handlePurchaseResult(
    _ permissions: [String: Qonversion.Permission],
    _ error: Error?,
    _ isCancelled: Bool,
    completion: @escaping BridgeCompletion
  ) {
    if let error = error as NSError? {
      let wrappedError = error.toSandwichError()
      wrappedError.additionalInfo["isCancelled"] = isCancelled
      
      return completion(nil, wrappedError)
    }
    
    let permissionsDict: [String: Any] = permissions.mapValues { $0.toMap() }.clearEmptyValues()
    
    completion(permissionsDict, nil)
  }
  
  private func subscribeOnAsyncEvents() {
    guard !isSubscribedOnAsyncEvents else { return }
    
    Qonversion.setPurchasesDelegate(self)
    Qonversion.setPromoPurchasesDelegate(self)
    
    isSubscribedOnAsyncEvents = true
  }
}

// MARK: - PurchasesDelegate

extension QonversionSandwich: Qonversion.PurchasesDelegate {
  public func qonversionDidReceiveUpdatedPermissions(_ permissions: [String : Qonversion.Permission]) {
    let permissionsDict: BridgeData = permissions.mapValues { $0.toMap() }.clearEmptyValues()
    
    qonversionEventListener?.qonversionDidReceiveUpdatedPermissions(permissionsDict as [String: Any])
  }
}

// MARK: - PromoPurchasesDelegate

extension QonversionSandwich: QNPromoPurchasesDelegate {
  public func shouldPurchasePromoProduct(withIdentifier productID: String, executionBlock: @escaping Qonversion.PromoPurchaseCompletionHandler) {
    promoPurchasesExecutionBlocks[productID] = executionBlock
    
    qonversionEventListener?.shouldPurchasePromoProduct(with: productID)
  }
}
