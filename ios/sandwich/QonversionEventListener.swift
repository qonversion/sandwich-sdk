//
//  QonversionEventListener.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 13.04.2022.
//

import Foundation

public protocol QonversionEventListener {
  
  func qonversionDidReceiveUpdatedPermissions(_ permissions: BridgeData)
  
  func shouldPurchasePromoProduct(with productId: String)
}
