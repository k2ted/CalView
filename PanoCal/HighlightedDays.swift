//
//  HighlightedDay.swift
//  PanoCal
//
//  Created by Donald Edwards on 11/11/2026.
//

import SwiftUI

private struct HighlightedDaysKey: EnvironmentKey {
    static let defaultValue: ClosedRange<Date>? = nil
}

extension EnvironmentValues {
    var highlightedDays: ClosedRange<Date>? {
        get { self[HighlightedDaysKey.self] }
        set { self[HighlightedDaysKey.self] = newValue }
    }
}
