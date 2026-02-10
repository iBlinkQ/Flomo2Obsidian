//
//  Color+Theme.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import SwiftUI

extension Color {
    // Flomo brand green
    static let flomoGreen = Color(red: 0.0, green: 0.784, blue: 0.325) // #00C853

    // Obsidian brand purple
    static let obsidianPurple = Color(red: 0.486, green: 0.235, blue: 0.929) // #7C3CED

    // Gradient colors for different contexts
    static let brandGradientStart = flomoGreen
    static let brandGradientEnd = obsidianPurple

    // Helper for creating brand gradients
    static func brandGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(
            colors: [brandGradientStart, brandGradientEnd],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}
