//
//  AutomationsSandwich.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 13.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation
import Qonversion

class AutomationsSandwich : NSObject {
  private var automationsEventListener: AutomationsEventListener?
  
  public func subscribe(_ automationsEventListener: AutomationsEventListener) {
    self.automationsEventListener = automationsEventListener
    Qonversion.Automations.setDelegate(self)
  }
}

extension AutomationsSandwich: Qonversion.AutomationsDelegate {
  public func automationsDidShowScreen(_ screenID: String) {
    let payload: BridgeData = ["screenId": screenID]
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.screenShown.rawValue, payload: payload)
  }
  
  public func automationsDidStartExecuting(actionResult: Qonversion.ActionResult) {
    let payload: BridgeData = actionResult.toMap()
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.actionStarted.rawValue, payload: payload)
  }
  
  public func automationsDidFailExecuting(actionResult: Qonversion.ActionResult) {
    let payload: BridgeData = actionResult.toMap()
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.actionFailed.rawValue, payload: payload)
  }
  
  public func automationsDidFinishExecuting(actionResult: Qonversion.ActionResult) {
    let payload: BridgeData = actionResult.toMap()
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.actionFinished.rawValue, payload: payload)
  }
  
  public func automationsFinished() {
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.automationsFinished.rawValue, payload: nil)
  }
}
