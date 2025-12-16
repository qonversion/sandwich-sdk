//
//  NoCodesPurchaseDelegateBridge.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 28.11.2025.
//  Copyright © 2025 Qonversion Inc. All rights reserved.
//

import Foundation

@objc public protocol NoCodesPurchaseDelegateBridge {
  @objc func purchase(_ product: [String: Any])
  @objc func restore()
}
