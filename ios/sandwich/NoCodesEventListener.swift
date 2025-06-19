//
//  NoCodesEventListener.swift
//  QonversionSandwich
//
//  Created by Suren Sarkisyan on 08.05.2025.
//  Copyright © 2025 Qonversion Inc. All rights reserved.
//

import Foundation

@objc public protocol NoCodesEventListener {
    @objc func noCodesDidTrigger(event: String, payload: [String: Any]?)
}

public enum NoCodesEvent: String {
    case screenShown = "nocodes_screen_shown"
    case finished = "nocodes_finished"
    case actionStarted = "nocodes_action_started"
    case actionFailed = "nocodes_action_failed"
    case actionFinished = "nocodes_action_finished"
    case screenFailedToLoad = "nocodes_screen_failed_to_load"
}
