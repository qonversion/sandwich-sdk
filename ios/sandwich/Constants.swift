//
//  Constants.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 12.04.2022.
//

import Foundation

struct UserDefaultsConstants {
    static let sourceKey = "com.qonversion.keys.source"
    static let sourceVersionKey = "com.qonversion.keys.sourceVersion"
}

public typealias BridgeData = [String: Any?]
public typealias BridgeCompletion = (_ result: BridgeData?, _ error: BridgeData?) -> Void
