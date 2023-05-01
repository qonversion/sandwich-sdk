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
  
  @objc public func initialize(
    projectKey: String,
    launchModeKey: String,
    environmentKey: String? = nil,
    entitlementsCacheLifetimeKey: String? = nil,
    proxyUrl: String? = nil
  ) {
    guard let launchMode = Qonversion.LaunchMode.fromString(launchModeKey) else { return }
    
    let config = Qonversion.Configuration(projectKey: projectKey, launchMode: launchMode)
    config.setEntitlementsUpdateListener(self)
    
    if let env = Qonversion.Environment.fromString(environmentKey) {
      config.setEnvironment(env)
    }
    
    if let cacheLifetime = Qonversion.EntitlementsCacheLifetime.fromString(entitlementsCacheLifetimeKey) {
      config.setEntitlementsCacheLifetime(cacheLifetime)
    }
    
    if let proxyUrl = proxyUrl {
      config.setProxyURL(proxyUrl);
    }
    
    Qonversion.initWithConfig(config)
    
    subscribeOnAsyncEvents()
  }
  
  @objc public func storeSdkInfo(source: String, version: String) {
    let defaults = UserDefaults.standard
    defaults.set(source, forKey: UserDefaultsConstants.sourceKey)
    defaults.set(version, forKey: UserDefaultsConstants.sourceVersionKey)
  }
  
  @objc public func syncHistoricalData() {
    Qonversion.shared().syncHistoricalData()
  }
  
  @objc public func syncStoreKit2Purchases() {
    QonversionSwift.shared.syncStoreKit2Purchases()
  }
  
  // MARK: Product Center
  
  @objc public func purchase(_ productId: String, completion: @escaping BridgeCompletion) {
    let purchaseCompletion = getPurchaseCompletionHandler(for: completion)
    Qonversion.shared().purchase(productId, completion: purchaseCompletion)
  }
  
  @objc public func purchaseProduct(_ productId: String, offeringId: String?, completion: @escaping BridgeCompletion) {
    guard let offeringId = offeringId else {
      return purchase(productId, completion: completion)
    }
    
    loadProduct(productId, offeringId) { [weak self] (product) in
      guard let self = self else { return }
      
      guard let product = product else {
        return self.purchase(productId, completion: completion)
      }

      let purchaseCompletion = self.getPurchaseCompletionHandler(for: completion)
      Qonversion.shared().purchaseProduct(product, completion: purchaseCompletion)
    }
  }
  
  @objc public func promoPurchase(_ productId: String, completion: @escaping BridgeCompletion) {
    if let executionBlock = promoPurchasesExecutionBlocks[productId] {
      promoPurchasesExecutionBlocks[productId] = nil

      executionBlock { [weak self] (entitlements, error, isCancelled) in
        self?.handlePurchaseResult(entitlements, error, isCancelled, completion: completion)
      }
    } else {
      let error = NSError.init(domain: keyQONErrorDomain, code: Qonversion.Error.productNotFound.rawValue, userInfo: nil)
      
      completion(nil, error.toSandwichError())
    }
  }
  
  @objc public func checkEntitlements(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().checkEntitlements { (entitlements, error) in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let entitlementsDict: [String: Any] = entitlements.mapValues { $0.toMap() }.clearEmptyValues()
      
      completion(entitlementsDict, nil)
    }
  }
  
  @objc public func offerings(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().offerings { offerings, error in
      if let error = error as NSError? {
        completion(nil, error.toSandwichError())
      }
      
      let bridgeData: [String: Any]? = offerings?.toMap().clearEmptyValues()
      
      completion(bridgeData, nil)
    }
  }
  
  @objc public func products(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().products { (products, error) in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let productsDict: [String: Any] = products.mapValues { $0.toMap() }.clearEmptyValues()
      
      completion(productsDict, nil)
    }
  }
  
  @objc public func restore(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().restore { (entitlements, error) in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let entitlementsDict: [String: Any] = entitlements.mapValues { $0.toMap() }.clearEmptyValues()
      
      completion(entitlementsDict, nil)
    }
  }
  
  @objc public func checkTrialIntroEligibility(_ ids: [String], completion: @escaping BridgeCompletion) {
    Qonversion.shared().checkTrialIntroEligibility(ids) { eligibilities, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      let eligibilitiesDict: [String: Any] = eligibilities.mapValues { $0.toMap() }.clearEmptyValues()

      completion(eligibilitiesDict, nil)
    }
  }
  
#if os(iOS)
  @available (iOS 14.0, *)
  @objc public func presentCodeRedemptionSheet() {
    Qonversion.shared().presentCodeRedemptionSheet()
  }
#endif
  
  // MARK: User Info
  
  @objc public func identify(_ userId: String) {
    Qonversion.shared().identify(userId)
  }
  
  @objc public func setDefinedProperty(_ property: String, value: String) {
    guard let parsedProperty = Qonversion.Property.fromString(property) else { return }

    Qonversion.shared().setProperty(parsedProperty, value: value)
  }
  
  @objc public func setCustomProperty(_ property: String, value: String) {
    Qonversion.shared().setUserProperty(property, value: value)
  }
  
  @objc public func logout() {
    Qonversion.shared().logout()
  }

  @objc public func userInfo(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().userInfo { userInfo, error in
      if let error = error as NSError? {
        completion(nil, error.toSandwichError())
      }

      let bridgeData: [String: Any]? = userInfo?.toMap().clearEmptyValues()
      
      completion(bridgeData, nil)
    }
  }

  @objc public func attribution(providerKey: String, value: [String: Any]) {
    guard let provider = Qonversion.AttributionProvider.fromString(providerKey) else { return }

    Qonversion.shared().attribution(value, from: provider)
  }

  @objc public func collectAppleSearchAdsAttribution() {
    Qonversion.shared().collectAppleSearchAdsAttribution()
  }
  
  @objc public func collectAdvertisingId() {
    Qonversion.shared().collectAdvertisingId()
  }
  
  // MARK: - Private functions
  
  private func loadProduct(_ productId: String, _ offeringId: String, completion: @escaping ProductCompletion) {
    Qonversion.shared().offerings() { (offerings, error) in
      let offering: Qonversion.Offering? = offerings?.offering(for: offeringId)
      let product: Qonversion.Product? = offering?.product(for: productId)
     
      completion(product)
    }
  }
  
  private func getPurchaseCompletionHandler(for completion: @escaping BridgeCompletion) -> Qonversion.PurchaseCompletionHandler {
    let purchaseCompletion: Qonversion.PurchaseCompletionHandler = { [weak self] (entitlements, error, isCancelled) in
      self?.handlePurchaseResult(entitlements, error, isCancelled, completion: completion)
    }
    
    return purchaseCompletion
  }
  
  private func handlePurchaseResult(
    _ entitlements: [String: Qonversion.Entitlement],
    _ error: Error?,
    _ isCancelled: Bool,
    completion: @escaping BridgeCompletion
  ) {
    if let error = error as NSError? {
      let wrappedError = error.toSandwichError()
      wrappedError.additionalInfo["isCancelled"] = isCancelled
      
      return completion(nil, wrappedError)
    }
    
    let entitlementsDict: [String: Any] = entitlements.mapValues { $0.toMap() }.clearEmptyValues()
    
    completion(entitlementsDict, nil)
  }
  
  private func subscribeOnAsyncEvents() {
    guard !isSubscribedOnAsyncEvents else { return }
    
    Qonversion.shared().setEntitlementsUpdateListener(self)
    Qonversion.shared().setPromoPurchasesDelegate(self)
    
    isSubscribedOnAsyncEvents = true
  }
}

// MARK: - PurchasesDelegate

extension QonversionSandwich: Qonversion.EntitlementsUpdateListener {
  public func didReceiveUpdatedEntitlements(_ entitlements: [String : Qonversion.Entitlement]) {
    let entitlementsDict: BridgeData = entitlements.mapValues { $0.toMap() }.clearEmptyValues()
    
    qonversionEventListener?.qonversionDidReceiveUpdatedEntitlements(entitlementsDict as [String: Any])
  }
}

// MARK: - PromoPurchasesDelegate

extension QonversionSandwich: Qonversion.PromoPurchasesDelegate {
  public func shouldPurchasePromoProduct(withIdentifier productID: String, executionBlock: @escaping Qonversion.PromoPurchaseCompletionHandler) {
    promoPurchasesExecutionBlocks[productID] = executionBlock
    
    qonversionEventListener?.shouldPurchasePromoProduct(with: productID)
  }
}
