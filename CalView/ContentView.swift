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
    @State private var selected: EventItem?
    @State private var selectedDay: DayItem?

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                HStack {
                    Picker("Range", selection: $months) {
                        Text("3 months").tag(3)
                        Text("6 months").tag(6)
                        Text("12 months").tag(12)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Button("Today") {
                        jumpToToday(proxy)
                    }

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
                                VStack(spacing: 4) {
                                    if let label = monthLabel(for: weekStart, index: index) {
                                        Text(label)
                                            .font(.headline)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top, 8)
                                    }
                                    WeekRow(
                                        weekStart: weekStart,
                                        events: calendar.visibleEvents,
                                        onSelect: { selected = EventItem(event: $0) },
                                        onShowDay: { day, events in selectedDay = DayItem(day: day, events: events) }
                                    )
                                }
                                .id(weekStart)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .task(id: months) { await calendar.load(months: months) }
        .sheet(item: $selected) { item in
            EventDetailView(event: item.event)
        }
        .sheet(item: $selectedDay) { item in
            DayListView(day: item.day, events: item.events)
        }
    }

    private func jumpToToday(_ proxy: ScrollViewProxy) {
        let cal = Calendar.current
        guard let monthStart = cal.dateInterval(of: .month, for: Date())?.start else { return }
        if let week = calendar.weekStarts.first(where: {
            cal.isDate(monthStart, equalTo: $0, toGranularity: .weekOfYear)
        }) {
            withAnimation {
                proxy.scrollTo(week, anchor: .top)
            }
        }
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
