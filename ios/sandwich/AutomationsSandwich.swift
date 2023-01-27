//
//  AutomationsSandwich.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 13.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation
import Qonversion

public class AutomationsSandwich : NSObject {
  private var automationsEventListener: AutomationsEventListener?

  private var defaultPresentationConfig: Qonversion.ScreenPresentationConfiguration? = nil
  private var screenPresentationConfigs: [String: Qonversion.ScreenPresentationConfiguration] = [:]
  private var isCustomizationDelegateSet = false
  
  @objc public func subscribe(_ automationsEventListener: AutomationsEventListener) {
    self.automationsEventListener = automationsEventListener
    Qonversion.Automations.shared().setDelegate(self)
  }

#if os(iOS)
  @objc public func setScreenPresentationConfig(_ configData: [String: Any], forScreenId screenId: String? = nil) {
    let config = configData.toScreenPresentationConfig()

    if (!isCustomizationDelegateSet) {
      isCustomizationDelegateSet = true
      Qonversion.Automations.shared().setScreenCustomizationDelegate(self)
    }

    if let screenId = screenId {
      screenPresentationConfigs[screenId] = config
    } else {
      screenPresentationConfigs = [:]
      defaultPresentationConfig = config
    }
  }

  @objc public func setNotificationToken(_ token: String) {
    let tokenData: Data = token.toData()
    Qonversion.Automations.shared().setNotificationsToken(tokenData)
  }
  
  @objc public func getNotificationCustomPayload(_ notificationData: [AnyHashable: Any]) -> [AnyHashable: Any]? {
    return Qonversion.Automations.shared().getNotificationCustomPayload(notificationData)
  }
  
  @objc public func handleNotification(_ notificationData: [AnyHashable: Any]) -> Bool {
    return Qonversion.Automations.shared().handleNotification(notificationData)
  }
  
  @objc public func showScreen(_ screenId: String, completion: @escaping BridgeCompletion) {
    Qonversion.Automations.shared().showScreen(withID: screenId) { success, error in
      if let error = error as NSError? {
        return completion(nil, error.toSandwichError())
      }

      completion(["success": success], nil);
    }
  }
#endif

  @objc public func getAvailableEvents() -> [String] {
    let availableEvents: [AutomationsEvent] = [
      .screenShown,
      .actionStarted,
      .actionFailed,
      .actionFinished,
      .automationsFinished
    ]

    return availableEvents.map { $0.rawValue }
  }
}

extension AutomationsSandwich: Qonversion.ScreenCustomizationDelegate {
  public func presentationConfigurationForScreen(_ screenID: String) -> Qonversion.ScreenPresentationConfiguration {
    return screenPresentationConfigs[screenID] ?? defaultPresentationConfig ?? Qonversion.ScreenPresentationConfiguration.default()
  }
}

extension AutomationsSandwich: Qonversion.AutomationsDelegate {
  public func automationsDidShowScreen(_ screenID: String) {
    let payload: BridgeData = ["screenId": screenID]
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.screenShown.rawValue, payload: payload.clearEmptyValues())
  }
  
  public func automationsDidStartExecuting(actionResult: Qonversion.ActionResult) {
    let payload: BridgeData = actionResult.toMap()
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.actionStarted.rawValue, payload: payload.clearEmptyValues())
  }
  
  public func automationsDidFailExecuting(actionResult: Qonversion.ActionResult) {
    let payload: BridgeData = actionResult.toMap()
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.actionFailed.rawValue, payload: payload.clearEmptyValues())
  }
  
  public func automationsDidFinishExecuting(actionResult: Qonversion.ActionResult) {
    let payload: BridgeData = actionResult.toMap()
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.actionFinished.rawValue, payload: payload.clearEmptyValues())
  }
  
  public func automationsFinished() {
    automationsEventListener?.automationDidTrigger(event: AutomationsEvent.automationsFinished.rawValue, payload: nil)
  }
}
