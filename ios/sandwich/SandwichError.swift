//
//  SandwichError.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 13.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation

@objc public class SandwichError: NSObject {
    @objc public let code: String
    @objc public let domain: String
    @objc public let details: String
    @objc public let additionalMessage: String?
    @objc public var additionalInfo: [String: Any]
    
    public init(code: String,
                domain: String,
                details: String,
                additionalMessage: String?,
                additionalInfo: [String: Any] = [:]) {
        self.code = code
        self.domain = domain
        self.details = details
        self.additionalMessage = additionalMessage
        self.additionalInfo = additionalInfo
    }
}
