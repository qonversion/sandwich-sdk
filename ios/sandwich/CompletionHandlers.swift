//
//  CompletionHandlers.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 13.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation
import Qonversion

public typealias BridgeData = [String: Any?]
public typealias BridgeCompletion = (_ result: BridgeData?, _ error: SandwichError?) -> Void
typealias ProductCompletion = (_ result: Qonversion.Product?) -> Void
