//
//  ContentView.swift
//  CalView
//
//  Created by Donald Edwards on 09/11/2026.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @State private var calendar = CalendarStore()
    @State private var months = 3
    @State private var showFilter = false

    var body: some View {
        VStack {
            HStack {
                Picker("Range", selection: $months) {
                    Text("3 months").tag(3)
                    Text("6 months").tag(6)
                    Text("12 months").tag(12)
                }
                .pickerStyle(.segmented)

                Button {
                    showFilter.toggle()
                } label: {
                    Label("Calendars", systemImage: "line.3.horizontal.decrease.circle")
                }
                .popover(isPresented: $showFilter) {
                    CalendarFilterView(calendar: calendar)
                }
            }
            .padding()

            if calendar.accessDenied {
                Text("Calendar access was denied. You can allow it in System Settings > Privacy & Security > Calendars.")
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(calendar.weekStarts.enumerated()), id: \.element) { index, weekStart in
                            if let label = monthLabel(for: weekStart, index: index) {
                                Text(label)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                            }
                            WeekRow(weekStart: weekStart, events: calendar.visibleEvents)
                        }
                    }
                    .padding()
                }
            }
        }
        .task(id: months) { await calendar.load(months: months) }
    }

    private func monthLabel(for weekStart: Date, index: Int) -> String? {
        let cal = Calendar.current
        for offset in 0..<7 {
            let day = cal.date(byAdding: .day, value: offset, to: weekStart)!
            if cal.component(.day, from: day) == 1 {
                return day.formatted(.dateTime.month(.wide).year())
            }
        }
        if index == 0 {
            return weekStart.formatted(.dateTime.month(.wide).year())
        }
        return nil
    }
}
