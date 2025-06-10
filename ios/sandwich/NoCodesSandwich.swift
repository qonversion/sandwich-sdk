//
//  NoCodesSandwich.swift
//  QonversionSandwich
//
//  Created by Suren Sarkisyan on 08.05.2025.
//  Copyright © 2025 Qonversion Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import NoCodes
import UIKit
#endif

public class NoCodesSandwich: NSObject {
    #if os(iOS)
    private var noCodesEventListener: NoCodesEventListener?
    private var defaultPresentationConfig: NoCodes.PresentationConfiguration? = nil
    private var screenPresentationConfigs: [String: NoCodes.PresentationConfiguration] = [:]
    private var isCustomizationDelegateSet = false
    #endif
    
    @objc public init(noCodesEventListener: NoCodesEventListener) {
        #if os(iOS)
        self.noCodesEventListener = noCodesEventListener
        #endif
    }
    
#if os(iOS)
    
    @objc public func initialize(projectKey: String) {
        let noCodesConfig = NoCodes.Configuration(projectKey: projectKey)
        
        NoCodes.initialize(with: noCodesConfig)
        NoCodes.shared.set(delegate: self)
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
            .screenClosed,
            .actionStarted,
            .actionFailed,
            .actionFinished,
            .screenFailedToLoad
        ]
        
        return availableEvents.map { $0.rawValue }
    }
    
#endif
}

#if os(iOS)
extension NoCodesSandwich: NoCodes.ScreenCustomizationDelegate {
    public func presentationConfigurationForScreen(contextKey: String) -> NoCodes.PresentationConfiguration {
        return screenPresentationConfigs[contextKey] ?? defaultPresentationConfig ?? .defaultConfiguration()
    }
    
    public func presentationConfigurationForScreen(id: String) -> NoCodes.PresentationConfiguration {
        return screenPresentationConfigs[id] ?? defaultPresentationConfig ?? .defaultConfiguration()
    }
    
    public func viewForPopoverPresentation() -> UIView? {
        return nil
    }
}

extension NoCodesSandwich: NoCodes.Delegate {
    public func controllerForNavigation() -> UIViewController? {
        return nil
    }
    
    public func noCodesHasShownScreen(id: String) {
        let payload: BridgeData = ["screenId": id]
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.screenShown.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesStartsExecuting(action: NoCodes.Action) {
        let payload: BridgeData = action.toMap()
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.actionStarted.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesFailedToExecute(action: NoCodes.Action, error: Error?) {
        var payload: BridgeData = action.toMap()
        if let error = error as NSError? {
            payload["error"] = error.toMap()
        }
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.actionFailed.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesFinishedExecuting(action: NoCodes.Action) {
        let payload: BridgeData = action.toMap()
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.actionFinished.rawValue, payload: payload.clearEmptyValues())
    }
    
    public func noCodesFinished() {
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.screenClosed.rawValue, payload: nil)
    }
    
    public func noCodesFailedToLoadScreen(error: Error?) {
        var payload: BridgeData = [:]
        if let error = error as NSError? {
            payload["error"] = error.toMap()
        }
        noCodesEventListener?.noCodesDidTrigger(event: NoCodesEvent.screenFailedToLoad.rawValue, payload: payload.clearEmptyValues())
    }
}
#endif
