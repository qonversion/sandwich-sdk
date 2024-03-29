//
//  AutomationsEventListener.swift
//  QonversionSandwich
//
//  Created by Kamo Spertsyan on 13.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

import Foundation

@objc public protocol AutomationsEventListener {

  @objc func automationDidTrigger(event: String, payload: [String: Any]?)
}

public enum AutomationsEvent: String {
  case screenShown = "automations_screen_shown"
  case actionStarted = "automations_action_started"
  case actionFailed = "automations_action_failed"
  case actionFinished = "automations_action_finished"
  case automationsFinished = "automations_finished"
}
