//
//  NoCodesSandwich.swift
//  QonversionSandwich
//
//  Created by Suren Sarkisyan on 08.05.2025.
//  Copyright © 2025 Qonversion Inc. All rights reserved.
//
#if os(iOS)

import Foundation
import Qonversion
import UIKit

public class NoCodesSandwich: NSObject {
    private var noCodesEventListener: NoCodesEventListener?
    private var defaultPresentationConfig: NoCodesPresentationConfiguration? = nil
    private var screenPresentationConfigs: [String: NoCodesPresentationConfiguration] = [:]
    private var isCustomizationDelegateSet = false
    
    @objc public init(noCodesEventListener: NoCodesEventListener) {
        self.noCodesEventListener = noCodesEventListener
    }

    @objc public func initialize(projectKey: String) {
        let noCodesConfig = NoCodesConfiguration(projectKey: projectKey)
        
        NoCodes.initialize(with: noCodesConfig)
        NoCodes.shared.set(delegate: self)
    }
  
    @objc public func storeSdkInfo(source: String, version: String) {
        // Does nothing on iOS as No-Codes are integrated into the Qonversion SDK and share its source and version
    }
    
    @MainActor @objc public func setScreenPresentationConfig(_ configData: [String: Any], forContextKey contextKey: String? = nil) {
        let config = configData.toPresentationConfig()
        
        if (!isCustomizationDelegateSet) {
            isCustomizationDelegateSet = true
            NoCodes.shared.set(screenCustomizationDelegate: self)
        }
        
        if let contextKey = contextKey {
            screenPresentationConfigs[contextKey] = config
        } else {
            screenPresentationConfigs = [:]
            defaultPresentationConfig = config
        }
    }
    
    @MainActor @objc public func showScreen(_ contextKey: String) {
        NoCodes.shared.showScreen(withContextKey: contextKey)
    }
    
    @MainActor @objc public func close() {
        NoCodes.shared.close()
    }
    
    @objc public func getAvailableEvents() -> [String] {
        let availableEvents: [NoCodesEvent] = [
            .screenShown,
            .finished,
            .actionStarted,
            .actionFailed,
            .actionFinished,
            .screenFailedToLoad
        ]
        
        return availableEvents.map { $0.rawValue }
    }
}

extension NoCodesSandwich: NoCodesScreenCustomizationDelegate {
    public func presentationConfigurationForScreen(contextKey: String) -> NoCodesPresentationConfiguration {
        return screenPresentationConfigs[contextKey] ?? defaultPresentationConfig ?? .defaultConfiguration()
    }
    
    public func presentationConfigurationForScreen(id: String) -> NoCodesPresentationConfiguration {
        return screenPresentationConfigs[id] ?? defaultPresentationConfig ?? .defaultConfiguration()
    }
    
    public func viewForPopoverPresentation() -> UIView? {
        return nil
    }
}

extension NoCodesSandwich: NoCodesDelegate {
    public func controllerForNavigation() -> UIViewController? {
        return nil
    }
    
    public func noCodesHasShownScreen(id: String) {
        let payload: BridgeData = ["screenId": id]
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.screenShown.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesStartsExecuting(action: NoCodesAction) {
        let payload: BridgeData = action.toMap()
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.actionStarted.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesFailedToExecute(action: NoCodesAction, error: Error?) {
        var payload: BridgeData = action.toMap()
        payload["error"] = errorToMap(error)
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.actionFailed.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesFinishedExecuting(action: NoCodesAction) {
        let payload: BridgeData = action.toMap()
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.actionFinished.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesFinished() {
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.finished.rawValue, payload: nil)
    }
    
    public func noCodesFailedToLoadScreen(error: Error?) {
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.screenFailedToLoad.rawValue, payload: errorToMap(error)?.clearEmptyValues())
    }
}
#endif
