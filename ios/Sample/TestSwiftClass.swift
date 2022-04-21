//
//  TestSwiftClass.swift
//  Sample
//
//  Created by Suren Sarkisyan on 20.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation
import QonversionSandwich

class TestSwiftClass {
    
    private lazy var sandwich = QonversionSandwich(qonversionEventListener: self)
    
    init() {
        functionToTestSwiftSandwich()
    }
    
    func functionToTestSwiftSandwich() {
        // write any code here
        
        
    }
}

// MARK: - QonversionEventListener

extension TestSwiftClass: QonversionEventListener {
    
    func qonversionDidReceiveUpdatedPermissions(_ permissions: [String : Any]) {
        
    }
    
    func shouldPurchasePromoProduct(with productId: String) {
        
    }
}
