//
//  JumpToMonthView.swift
//  PanoCal
//
//  Created by Donald Edwards on 13/11/2026.
//

import SwiftUI

struct JumpToMonthView: View {
    let onConfirm: (Date) -> Void
    let onCancel: () -> Void

    @State private var month: Int
    @State private var year: Int
    private let initialYear: Int

    init(current: Date, onConfirm: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        let parts = Calendar.current.dateComponents([.year, .month], from: current)
        _month = State(initialValue: parts.month ?? 1)
        _year = State(initialValue: parts.year ?? 2026)
        initialYear = parts.year ?? 2026
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    private var years: [Int] {
        let thisYear = Calendar.current.component(.year, from: Date())
        let low = min(thisYear - 10, initialYear)
        let high = max(thisYear + 20, initialYear)
        return Array(low...high)
    }

    private func confirm() {
        if let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) {
            onConfirm(date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Go to month")
                .font(.headline)

            HStack(spacing: 12) {
                Picker("Month", selection: $month) {
                    ForEach(1...12, id: \.self) { m in
                        Text(Calendar.current.monthSymbols[m - 1]).tag(m)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Picker("Year", selection: $year) {
                    ForEach(years, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            HStack {
                Spacer()
                Button("Cancel") { onCancel() }
                Button("Go") { confirm() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 320)
    }
}
