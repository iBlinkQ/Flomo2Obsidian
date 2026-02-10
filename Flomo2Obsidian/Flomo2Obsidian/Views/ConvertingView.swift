//
//  ConvertingView.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import SwiftUI

struct ConvertingView: View {
    let currentProgress: Int?
    let totalNotes: Int?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Converting notes...")
                .font(.title3)

            if let current = currentProgress, let total = totalNotes {
                Text("Processing \(current) of \(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
