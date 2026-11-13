//
//  AppearanceSetting.swift
//  PanoCal
//
//  Created by Donald Edwards on 13/11/2026.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum AppearanceSetting {
    // setting is "system", "light" or "dark"
    static func apply(_ setting: String) {
        #if os(macOS)
        switch setting {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
        #else
        let style: UIUserInterfaceStyle
        switch setting {
        case "light": style = .light
        case "dark": style = .dark
        default: style = .unspecified
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
        #endif
    }
}
