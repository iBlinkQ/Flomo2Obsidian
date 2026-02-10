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

    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Subtle background gradient
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }

                    VStack(spacing: 16) {
                        Text("Converting Notes")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        if let current = currentProgress, let total = totalNotes {
                            VStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Text("\(current)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.blue)
                                    Text("of")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.secondary)
                                    Text("\(total)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }

                                if total > 0 {
                                    VStack(spacing: 8) {
                                        ProgressView(value: Double(current), total: Double(total))
                                            .tint(.blue)
                                            .frame(width: 280)

                                        Text("\(Int((Double(current) / Double(total)) * 100))%")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } else {
                            Text("Preparing conversion...")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.secondary.opacity(0.06),
                                    Color.secondary.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

                Spacer()
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
