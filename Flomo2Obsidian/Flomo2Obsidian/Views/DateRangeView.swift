//
//  DateRangeView.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import SwiftUI

struct DateRangeView: View {
    let totalNotes: Int
    let earliestDate: Date
    let latestDate: Date

    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectAll: Bool

    let onCancel: () -> Void
    let onConvert: () -> Void

    @State private var isHoveringConvert = false
    @State private var isHoveringCancel = false

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 32) {
                mainCard
                actionButtonsSection
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .windowBackgroundColor).opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var mainCard: some View {
        VStack(spacing: 32) {
            headerSection
            dateSelectionSection
        }
        .padding(40)
        .frame(minWidth: 800)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.secondary.opacity(0.04),
                            Color.secondary.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(.blue)

                Text("Select Date Range")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(totalNotes)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("notes discovered")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Text("from \(formatDate(earliestDate)) to \(formatDate(latestDate))")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
                    .tracking(0.2)
            }
        }
    }

    private var dateSelectionSection: some View {
        dateSelectionCard
    }

    private var dateSelectionCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            dateRangeRow
            selectAllToggle
        }
        .padding(28)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 18)
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
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private var dateRangeRow: some View {
        HStack(spacing: 24) {
            // Start Date
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    Text("Start Date")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }

                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            Divider()
                .frame(height: 60)
                .background(Color.secondary.opacity(0.2))

            // End Date
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    Text("End Date")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }

                DatePicker("", selection: $endDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
        }
    }

    private var selectAllToggle: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectAll.toggle()
                if selectAll {
                    startDate = earliestDate
                    endDate = latestDate
                }
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(selectAll ? Color.blue : Color.secondary.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: selectAll ? "checkmark" : "")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Select All Notes")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Use the entire date range")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .onChange(of: startDate) {
            checkAndUpdateSelectAll()
        }
        .onChange(of: endDate) {
            checkAndUpdateSelectAll()
        }
    }

    private var selectAllBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: selectAll ?
                        [Color.blue.opacity(0.08), Color.blue.opacity(0.08)] :
                        [Color.secondary.opacity(0.06), Color.secondary.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var selectAllBorder: some View {
        RoundedRectangle(cornerRadius: 18)
            .strokeBorder(
                selectAll ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.15),
                lineWidth: 1
            )
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(0.2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(isHoveringCancel ? 0.12 : 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .scaleEffect(isHoveringCancel ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveringCancel = hovering
                }
            }

            Button(action: onConvert) {
                HStack(spacing: 10) {
                    Text("Convert to Obsidian")
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(0.2)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(isHoveringConvert ? 0.9 : 1.0))
                )
                .shadow(
                    color: Color.blue.opacity(isHoveringConvert ? 0.4 : 0.3),
                    radius: isHoveringConvert ? 12 : 8,
                    x: 0,
                    y: isHoveringConvert ? 6 : 4
                )
                .scaleEffect(isHoveringConvert ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveringConvert = hovering
                }
            }
        }
        .padding(.top, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func checkAndUpdateSelectAll() {
        // Auto-uncheck if dates don't match full range
        let calendar = Calendar.current
        let isFullRange = calendar.isDate(startDate, inSameDayAs: earliestDate) &&
                         calendar.isDate(endDate, inSameDayAs: latestDate)

        if !isFullRange && selectAll {
            selectAll = false
        }
    }
}
