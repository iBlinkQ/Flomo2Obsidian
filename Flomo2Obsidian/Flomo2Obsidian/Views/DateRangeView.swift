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

    var body: some View {
        VStack(spacing: 24) {
            Text("Select Date Range")
                .font(.title)
                .fontWeight(.semibold)

            Text("Found \(totalNotes) notes\nfrom \(formatDate(earliestDate)) to \(formatDate(latestDate))")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }

                VStack(alignment: .leading) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            Toggle("Select All", isOn: $selectAll)
                .onChange(of: selectAll) { newValue in
                    if newValue {
                        startDate = earliestDate
                        endDate = latestDate
                    }
                }

            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Convert") {
                    onConvert()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
