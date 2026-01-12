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
    
    if let proxyUrl = proxyUrl, !proxyUrl.isEmpty {
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
  
  @objc public func purchase(
    _ productId: String,
    quantity: Int,
    contextKeys: [String],
    promoOffer: [String: Any],
    completion: @escaping BridgeCompletion
  ) {
    Qonversion.shared().products { [weak self] result, err in
      guard let self = self else { return }
     
      let purchaseCompletion = getPurchaseCompletionHandler(for: completion)
      guard let product: Qonversion.Product = result[productId] else {
        let error = self.productNotFoundError()
        return purchaseCompletion([:], error, false)
      }
     
      let purchaseOptions: Qonversion.PurchaseOptions
      
      if #available(iOS 12.2, macOS 10.14.4, watchOS 6.2, tvOS 12.2, visionOS 1.0, *),
         let productDiscountId = promoOffer["productDiscountId"] as? String,
         let productDiscount = product.skProduct?.discounts.first(where: { $0.identifier == productDiscountId }),
         let keyIdentifier = promoOffer["keyIdentifier"] as? String,
         let nonce = promoOffer["nonce"] as? String,
         let nonceUUID = UUID(uuidString: nonce),
         let signature = promoOffer["signature"] as? String,
         let timestamp = promoOffer["timestamp"] as? Int {
        let timestampNumber = NSNumber(value: timestamp)
        let paymentDiscount = SKPaymentDiscount(identifier: productDiscountId, keyIdentifier: keyIdentifier, nonce: nonceUUID, signature: signature, timestamp: timestampNumber)
        
        let promotionalOffer = Qonversion.PromotionalOffer(productDiscount: productDiscount, paymentDiscount: paymentDiscount)
        purchaseOptions = Qonversion.PurchaseOptions(quantity: quantity, contextKeys: contextKeys, promoOffer: promotionalOffer)
      } else {
        purchaseOptions = Qonversion.PurchaseOptions(quantity: quantity, contextKeys: contextKeys)
      }
      
      Qonversion.shared().purchaseProduct(product, options: purchaseOptions, completion: purchaseCompletion)
    }
  }
  
  @objc public func getPromotionalOffer(_ productId: String, productDiscountId: String, completion: @escaping BridgeCompletion) {
    if #available(iOS 12.2, macOS 10.14.4, watchOS 6.2, tvOS 12.2, visionOS 1.0, *) {
      Qonversion.shared().products { [weak self] result, err in
        guard let self = self else { return }
        
        guard let product: Qonversion.Product = result[productId],
              let discount: SKProductDiscount = product.skProduct?.discounts.first(where: { $0.identifier == productDiscountId }) else {
          let error = productNotFoundError()
          
          return completion(nil, error.toSandwichError())
        }
        Qonversion.shared().getPromotionalOffer(for: product, discount: discount) { promoOffer, error in
          if let error = error as NSError? {
            return completion(nil, error.toSandwichError())
          }
          
          let bridgeData: [String: Any]? = promoOffer?.toMap().clearEmptyValues()
          
          completion(bridgeData, nil)
        }
      }
    } else {
      let error = productNotFoundError()
      
      completion(nil, error.toSandwichError())
    }
  }
  
  @objc public func purchaseProduct(_ productId: String, offeringId: String?, completion: @escaping BridgeCompletion) {
    guard let offeringId = offeringId, !offeringId.isEmpty else {
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
  
  // MARK: - Purchase with Result
  
  @objc public func purchaseWithResult(
    _ productId: String,
    quantity: Int,
    contextKeys: [String],
    promoOffer: [String: Any],
    completion: @escaping BridgeCompletion
  ) {
    Qonversion.shared().products { [weak self] products, _ in
      guard let self = self else { return }
      
      guard let product = products[productId] else {
        let error = self.productNotFoundError()
        return completion(nil, error.toSandwichError())
      }
      
      let purchaseOptions: Qonversion.PurchaseOptions
      
      if #available(iOS 12.2, macOS 10.14.4, watchOS 6.2, tvOS 12.2, visionOS 1.0, *),
         let productDiscountId = promoOffer["productDiscountId"] as? String,
         let productDiscount = product.skProduct?.discounts.first(where: { $0.identifier == productDiscountId }),
         let keyIdentifier = promoOffer["keyIdentifier"] as? String,
         let nonce = promoOffer["nonce"] as? String,
         let nonceUUID = UUID(uuidString: nonce),
         let signature = promoOffer["signature"] as? String,
         let timestamp = promoOffer["timestamp"] as? Int {
        let timestampNumber = NSNumber(value: timestamp)
        let paymentDiscount = SKPaymentDiscount(identifier: productDiscountId, keyIdentifier: keyIdentifier, nonce: nonceUUID, signature: signature, timestamp: timestampNumber)
        
        let promotionalOffer = Qonversion.PromotionalOffer(productDiscount: productDiscount, paymentDiscount: paymentDiscount)
        purchaseOptions = Qonversion.PurchaseOptions(quantity: quantity, contextKeys: contextKeys, promoOffer: promotionalOffer)
      } else {
        purchaseOptions = Qonversion.PurchaseOptions(quantity: quantity, contextKeys: contextKeys)
      }
      
      Qonversion.shared().purchase(product, options: purchaseOptions) { purchaseResult in
        let bridgeData: [String: Any]? = purchaseResult.toMap().clearEmptyValues()
        completion(bridgeData, nil)
      }
    }
  }
  
  @objc public func promoPurchase(_ productId: String, completion: @escaping BridgeCompletion) {
    if let executionBlock = promoPurchasesExecutionBlocks[productId] {
      promoPurchasesExecutionBlocks[productId] = nil

      executionBlock { [weak self] (entitlements, error, isCancelled) in
        self?.handleEntitlementsResult(entitlements, error, completion: completion)
      }
    } else {
      let error = productNotFoundError()
      
      completion(nil, error.toSandwichError())
    }
  }
  
  @objc public func checkEntitlements(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().checkEntitlements { [weak self] (entitlements, error) in
      self?.handleEntitlementsResult(entitlements, error, completion: completion)
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
    Qonversion.shared().restore { [weak self] (entitlements, error) in
      self?.handleEntitlementsResult(entitlements, error, completion: completion)
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
  @available(iOS 14.0, *)
  @objc public func presentCodeRedemptionSheet() {
    Qonversion.shared().presentCodeRedemptionSheet()
  }
#endif
  
  // MARK: User Info
  
  @objc public func identify(_ userId: String, _ completion: @escaping BridgeCompletion) {
    Qonversion.shared().identify(userId) { userInfo, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }

      let bridgeData: [String: Any]? = userInfo?.toMap().clearEmptyValues()
      
      completion(bridgeData, nil)
    }
  }
  
  @objc public func setDefinedProperty(_ property: String, value: String) {
    guard let parsedProperty = Qonversion.UserPropertyKey.fromString(property) else { return }

    Qonversion.shared().setUserProperty(parsedProperty, value: value)
  }
  
  @objc public func setCustomProperty(_ property: String, value: String) {
    Qonversion.shared().setCustomUserProperty(property, value: value)
  }

  @objc public func userProperties(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().userProperties { userProperties, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }

      let bridgeData: [String: Any]? = userProperties?.toMap().clearEmptyValues()
      
      completion(bridgeData, nil)
    }
  }
  
  @objc public func logout() {
    Qonversion.shared().logout()
  }

  @objc public func userInfo(_ completion: @escaping BridgeCompletion) {
    Qonversion.shared().userInfo { userInfo, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
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
  
  @objc public func remoteConfig(_ contextKey: String?, _ completion: @escaping BridgeCompletion) {
    let sandwichCompletion: Qonversion.RemoteConfigCompletionHandler = { remoteConfig, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }

      let bridgeData: [String: Any]? = remoteConfig?.toMap().clearEmptyValues()
      completion(bridgeData, nil)
    }

    if let contextKey = contextKey, !contextKey.isEmpty {
      return Qonversion.shared().remoteConfig(contextKey: contextKey, completion: sandwichCompletion)
    }
    
    Qonversion.shared().remoteConfig(sandwichCompletion)
  }
  
  @objc public func remoteConfigList(_ contextKeys: [String], includeEmptyContextKey: Bool, _ completion: @escaping BridgeCompletion) {
    let sandwichCompletion: Qonversion.RemoteConfigListCompletionHandler = { remoteConfigList, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }

      let bridgeData: [String: Any]? = remoteConfigList?.toMap().clearEmptyValues()
      completion(bridgeData, nil)
    }
    
    Qonversion.shared().remoteConfigList(contextKeys: contextKeys, includeEmptyContextKey: includeEmptyContextKey, completion: sandwichCompletion)
  }
  
  @objc public func remoteConfigList(_ completion: @escaping BridgeCompletion) {
    let sandwichCompletion: Qonversion.RemoteConfigListCompletionHandler = { remoteConfigList, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }

      let bridgeData: [String: Any]? = remoteConfigList?.toMap().clearEmptyValues()
      completion(bridgeData, nil)
    }
    
    Qonversion.shared().remoteConfigList(sandwichCompletion)
  }
  
  @objc public func attachUserToExperiment(with experimentId: String, groupId: String, completion: @escaping BridgeCompletion) {
    Qonversion.shared().attachUser(toExperiment: experimentId, groupId: groupId) { success, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      completion(self.defaultResponse(success: true), nil)
    }
  }
  
  @objc public func detachUserFromExperiment(with experimentId: String, completion: @escaping BridgeCompletion) {
    Qonversion.shared().detachUser(fromExperiment: experimentId, completion: { success, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      completion(self.defaultResponse(success: true), nil)
    })
  }
  
  @objc public func attachUserToRemoteConfiguration(with remoteConfigurationId: String, completion: @escaping BridgeCompletion) {
    Qonversion.shared().attachUser(toRemoteConfiguration: remoteConfigurationId) { success, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      completion(self.defaultResponse(success: true), nil)
    }
  }
  
  @objc public func detachUserFromRemoteConfiguration(with remoteConfigurationId: String, completion: @escaping BridgeCompletion) {
    Qonversion.shared().detachUser(fromRemoteConfiguration: remoteConfigurationId, completion: { success, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }
      
      completion(self.defaultResponse(success: true), nil)
    })
  }
  
  @objc public func isFallbackFileAccessible(completion: @escaping BridgeCompletion) {
    let isAccessible: Bool = Qonversion.shared().isFallbackFileAccessible()
    
    completion(self.defaultResponse(success: isAccessible), nil)
  }
  
  // MARK: - Private functions
  
  private func defaultResponse(success: Bool) -> [String: Any] {
    return ["success": success]
  }
  
  private func loadProduct(_ productId: String, _ offeringId: String, completion: @escaping ProductCompletion) {
    Qonversion.shared().offerings() { (offerings, error) in
      let offering: Qonversion.Offering? = offerings?.offering(for: offeringId)
      let product: Qonversion.Product? = offering?.product(for: productId)
     
      completion(product)
    }
  }
  
  private func getPurchaseCompletionHandler(for completion: @escaping BridgeCompletion) -> Qonversion.PurchaseCompletionHandler {
    let purchaseCompletion: Qonversion.PurchaseCompletionHandler = { [weak self] (entitlements, error, isCancelled) in
      self?.handleEntitlementsResult(entitlements, error, completion: completion)
    }
    
    return purchaseCompletion
  }
  
  private func handleEntitlementsResult(
    _ entitlements: [String: Qonversion.Entitlement],
    _ error: Error?,
    completion: @escaping BridgeCompletion
  ) {
    if let error = error as NSError? {
      return completion(nil, error.toSandwichError())
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
      
    private func productNotFoundError() -> NSError {
      let error = NSError.init(domain: QonversionErrorDomain, code: Qonversion.ErrorCode.productNotFound.rawValue, userInfo: nil)
      
      return error
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
