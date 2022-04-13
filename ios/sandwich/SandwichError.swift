//
//  SandwichError.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 13.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

public struct SandwichError {
  let code: String
  let domain: String
  let details: String
  let additionalMessage: String?
  var additionalInfo: [String: Any?] = [:]
}
